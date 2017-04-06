在ASP.NET MVC 中发送邮件
============================================

.. contents:: Table of Contents
   :local:
   :depth: 2

们从一个简单的例子开始：您正在使用ASP.NET MVC构建您自己的博客，并希望收到每个相关文章评论的电子邮件通知。 我们将使用简单好用的 `Postal <http://aboutcode.net/postal/>`_ 库发送邮件。

.. tip::

   我准备了一个只有评论列表的简单应用程序， 您可以 `下载源码 <https://github.com/odinserj/Hangfire.Mailer/releases/tag/vBare>`_ 开始教程。

您已经有一个控制器操作来创建新的评论，并希望添加通知功能。

.. code-block:: c#

    // ~/HomeController.cs

    [HttpPost]
    public ActionResult Create(Comment model)
    {
        if (ModelState.IsValid)
        {
            _db.Comments.Add(model);
            _db.SaveChanges();
        }

        return RedirectToAction("Index");
    }

安装 Postal
------------------

首先, 安装 ``Postal`` 软件包:

.. code-block:: powershell

   Install-Package Postal.Mvc5

然后, 如下文创建 ``~/Models/NewCommentEmail.cs`` 文件:

.. code-block:: c#

    using Postal;

    namespace Hangfire.Mailer.Models
    {
        public class NewCommentEmail : Email
        {
            public string To { get; set; }
            public string UserName { get; set; }
            public string Comment { get; set; }
        }
    }

添加 ``~/Views/Emails/NewComment.cshtml`` 文件，为此电子邮件创建相应的模板：

.. code-block:: text

    @model Hangfire.Mailer.Models.NewCommentEmail
    To: @Model.To
    From: mailer@example.com
    Subject: New comment posted

    Hello, 
    There is a new comment from @Model.UserName:

    @Model.Comment

    <3

通过 ``Create`` 控制器调用Postal发送电子邮件:

.. code-block:: c#

    [HttpPost]
    public ActionResult Create(Comment model)
    {
        if (ModelState.IsValid)
        {
            _db.Comments.Add(model);
            _db.SaveChanges();

            var email = new NewCommentEmail
            {
                To = "yourmail@example.com",
                UserName = model.UserName,
                Comment = model.Text
            };

            email.Send();
        }

        return RedirectToAction("Index");
    }

然后在 ``web.config`` 文件中配置调用方法（ (默认情况下，本教程使用 ``C:\Temp`` 目录来存储发送出去的邮件):

.. code-block:: xml

  <system.net>
    <mailSettings>
      <smtp deliveryMethod="SpecifiedPickupDirectory">
        <specifiedPickupDirectory pickupDirectoryLocation="C:\Temp\" />
      </smtp>
    </mailSettings>
  </system.net>

就这样。尝试发表一些评论，您将在目录中看到通知。

进一步思考
-----------------------

为什么让用户等待通知发送？ 应该使用某些方法在后台异步发送电子邮件，以便尽快向响应用户请求。

然而， `异步 <http://www.asp.net/mvc/tutorials/mvc-4/using-asynchronous-methods-in-aspnet-mvc-4>`_ 控制器在这种情况下 `没有帮助 <http://blog.stephencleary.com/2012/08/async-doesnt-change-http-protocol.html>`_ ， 因为它们在等待异步操作完成时不会立即响应用户请求。它们只解决与线程池和应用程序的内部问题。

后台线程同样也有 `很大的问题 <http://blog.stephencleary.com/2012/12/returning-early-from-aspnet-requests.html>`_ 。您必须在ASP.NET应用程序中使用线程池线程或自定义线程池。然而在应用程序回收线程时您会丢失电子邮件 (即使您在ASP.NET 中实现了 ``IRegisteredObject`` 接口).

而您不太可能想要安装外部Windows服务或使用带控制台应用程序的 Windows Scheduler 来解决这个简单的问题 (只是个人博客项目，又不是电子商务解决方案)。

安装 Hangfire
--------------------

为了能够将任务放在后台，在应用程序重新启动期间不会丢失任务，我们将使用 `Hangfire <http://hangfire.io>`_ 。它可以在ASP.NET应用程序中以可靠的方式处理后台作业，而无需外部Windows服务或Windows Scheduler。

.. code-block:: powershell

   Install-Package Hangfire

Hangfire使用 SQL Server 或者 Redis 来存储有关后台任务的信息。配置它并在项目根目录新增一个 Startup 类:

.. code-block:: c#

       public class Startup
    {
        public void Configuration(IAppBuilder app)
        {
            GlobalConfiguration.Configuration
                .UseSqlServerStorage(
                    "MailerDb",
                    new SqlServerStorageOptions { QueuePollInterval = TimeSpan.FromSeconds(1) });


            app.UseHangfireDashboard();
            app.UseHangfireServer();


        }

    }


``SqlServerStorage`` 类会在应用程序启动时自动安装所有数据库表（但你也可以手工）。

现在我们可以使用 Hangfire 了。 我们封装一个在后台执行的公共方法：

.. code-block:: c#

    [HttpPost]
    public ActionResult Create(Comment model)
    {
        if (ModelState.IsValid)
        {
            _db.Comments.Add(model);
            _db.SaveChanges();

            BackgroundJob.Enqueue(() => NotifyNewComment(model.Id));
        }

        return RedirectToAction("Index");
    }

注意，我们传递的是一个评论的标识符而不是评论的全部信息 – Hangfire 将序列化所有的参数为字符串。默认情况下， serializer 不需要序列化整个的 ``Comment`` 类。另外，使用标识符以比完整的评论实体占用更小的空间。

现在，我们需要准备在后台调用的 ``NotifyNewComment`` 方法。请注意， ``HttpContext.Current`` 在这种情况下不可用，但是 Postal 库却可以 `在  ASP.NET 请求之外 <http://aboutcode.net/postal/outside-aspnet.html>`_ 使用。 在此之前先安装另一个软件包 (Postal 版本需要为0.9.2, 参阅 `issue <https://github.com/andrewdavey/postal/issues/68>`_) 。我们来更新包并引入RazorEngine。

.. code-block:: powershell

   Update-Package -save

.. code-block:: c#

    public static void NotifyNewComment(int commentId)
    {
        // Prepare Postal classes to work outside of ASP.NET request
        var viewsPath = Path.GetFullPath(HostingEnvironment.MapPath(@"~/Views/Emails"));
        var engines = new ViewEngineCollection();
        engines.Add(new FileSystemRazorViewEngine(viewsPath));

        var emailService = new EmailService(engines);

        // Get comment and send a notification.
        using (var db = new MailerDbContext())
        {
            var comment = db.Comments.Find(commentId);

            var email = new NewCommentEmail
            {
                To = "yourmail@example.com",
                UserName = comment.UserName,
                Comment = comment.Text
            };

            emailService.Send(email);
        }
    }

这是一个简单的C＃静态方法。 我们正在创建一个 ``EmailService`` 实例，找到指定的评论并使用 Postal 发送邮件。足够简单吧，特别是与自定义的Windows服务解决方案相比。

.. warning::

   电子邮件在请求管道之外发送。由于Postal 1.0.0, 存在以下 `限制 <http://aboutcode.net/postal/outside-aspnet.html>`_: 您不能使用 views 和 ``ViewBag``， 必须是 ``Model`` ;同样的，嵌入图像也是 `不支持 <https://github.com/andrewdavey/postal/issues/44>`_ 。

就这样！尝试发布一些评论并查看 ``C:\Temp`` 路径。你也可以在 ``http://<your-app>/hangfire`` 检查你的后台任务。如果您有任何问题，欢迎使用下面的评论表。

.. note::

   如果遇到程序集加载异常，请从 ``web.config`` 文件中删除以下部分 (我忘了这样做，但不想重新创建存储库):

   .. code-block:: xml

      <dependentAssembly>
        <assemblyIdentity name="Newtonsoft.Json" publicKeyToken="30ad4fe6b2a6aeed" culture="neutral" />
        <bindingRedirect oldVersion="0.0.0.0-6.0.0.0" newVersion="6.0.0.0" />
      </dependentAssembly>
      <dependentAssembly>
        <assemblyIdentity name="Common.Logging" publicKeyToken="af08829b84f0328e" culture="neutral" />
        <bindingRedirect oldVersion="0.0.0.0-2.2.0.0" newVersion="2.2.0.0" />
      </dependentAssembly>

自动重试
------------------

当 ``emailService.Send`` 方法引发异常时，Hangfire会在延迟一段时间(每次重试都会增加)后自动重试。重试次数(默认 10 次 )有限, 但您可以增加它。只需将 ``AutomaticRetryAttribute`` 加到 ``NotifyNewComment`` 方法:

.. code-block:: c#

   [AutomaticRetry( Attempts = 20 )]
   public static void NotifyNewComment(int commentId)
   {
       /* ... */
   }

日志
--------

当超过最大重试次数时，可以记录日志。尝试创建以下类：

.. code-block:: c#

    public class LogFailureAttribute : JobFilterAttribute, IApplyStateFilter
    {
        private static readonly ILog Logger = LogProvider.GetCurrentClassLogger();

        public void OnStateApplied(ApplyStateContext context, IWriteOnlyTransaction transaction)
        {
            var failedState = context.NewState as FailedState;
            if (failedState != null)
            {
                Logger.ErrorException(
                    String.Format("Background job #{0} was failed with an exception.", context.JobId), 
                    failedState.Exception);
            }
        }

        public void OnStateUnapplied(ApplyStateContext context, IWriteOnlyTransaction transaction)
        {
        }
    }

再添加:

通过在应用程序启动时调用以下方法来达到全局效果：

.. code-block:: c#

        public void Configuration(IAppBuilder app)
        {
            GlobalConfiguration.Configuration
                .UseSqlServerStorage(
                    "MailerDb",
                    new SqlServerStorageOptions { QueuePollInterval = TimeSpan.FromSeconds(1) })
                    .UseFilter(new LogFailureAttribute());

            app.UseHangfireDashboard();
            app.UseHangfireServer();
        }

或者局部应用于一个方法：

.. code-block:: c#

   [LogFailure]
   public static void NotifyNewComment(int commentId)
   {
       /* ... */
   }
   
当LogFailureAttribute命中一个方法时将会有新的日志。

使用您喜欢的任何常见的日志库，并且再做任何事情。以NLog为例。安装NLog（当前版本：4.2.3）。

.. code-block:: powershell

   Install-Package NLog

将新的 Nlog.config 文件加到项目的根目录中。
 
.. code-block:: xml

<?xml version="1.0" encoding="utf-8" ?>
<nlog xmlns="http://www.nlog-project.org/schemas/NLog.xsd"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      autoReload="true"
      throwExceptions="false">

  <variable name="appName" value="HangFire.Mailer" />

  <targets async="true">
    <target xsi:type="File"
            name="default"
            layout="${longdate} - ${level:uppercase=true}: ${message}${onexception:${newline}EXCEPTION\: ${exception:format=ToString}}"
            fileName="${specialfolder:ApplicationData}\${appName}\Debug.log"
            keepFileOpen="false"
            archiveFileName="${specialfolder:ApplicationData}\${appName}\Debug_${shortdate}.{##}.log"
            archiveNumbering="Sequence"
            archiveEvery="Day"
            maxArchiveFiles="30"
            />

    <target xsi:type="EventLog"
            name="eventlog"
            source="${appName}"
            layout="${message}${newline}${exception:format=ToString}"/>
  </targets>
  <rules>
    <logger name="*" writeTo="default" minlevel="Info" />
    <logger name="*" writeTo="eventlog" minlevel="Error" />
  </rules>
</nlog>

运行应用程序后 新的日志文件可以 %appdata%\HangFire.Mailer\Debug.log 找到。

修复重新部署
-----------------

如果在 ``NotifyNewComment`` 方法中出错, 您可以尝试并通过Web界面启动失败的后台任务来修复它：

.. code-block:: c#

   // Break background job by setting null to emailService:
   EmailService emailService = null;

编译一个项目，发布一个评论，然后打开 ``http://<your-app>/hangfire`` 的网页。超过所有自动重试的限制次数，然后修复任务中的bug，重新启动应用程序，最后点击 *Failed jobs* 页面上的 ``Retry`` 按钮。

保存语言区域
---------------------------

如果您为请求设置了自定义语言区域，则Hang​​fire将在后台作业执行期间存储和设置它。尝试以下：

.. code-block:: c#

   // HomeController/Create action
   Thread.CurrentThread.CurrentCulture = CultureInfo.GetCultureInfo("es-ES");
   BackgroundJob.Enqueue(() => NotifyNewComment(model.Id));

并在后台任务中检查：

.. code-block:: c#

    public static void NotifyNewComment(int commentId)
    {
        var currentCultureName = Thread.CurrentThread.CurrentCulture.Name;
        if (currentCultureName != "es-ES")
        {
            throw new InvalidOperationException(String.Format("Current culture is {0}", currentCultureName));
        }
        // ...
