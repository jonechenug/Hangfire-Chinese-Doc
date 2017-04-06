使ASP.NET应用程序始终运行
==========================================

默认情况下，Web应用程序中的Hangfire Server实例不会立即启动(.net core除外)，直到第一个用户访问您的站点。甚至，有一些事情会使您的Web应用程序在一段时间后关闭（空闲时和不同的应用程序池回收事件）。在这些情况下，您的 :doc:`周期任务 <../background-methods/performing-recurrent-tasks>` 和 :doc:`延迟任务 <../background-methods/calling-methods-with-delay>` 将不会入队， 同时 :doc:`排队中的任务 <../background-methods/calling-methods-in-background>` 也不会被执行。

小网站尤其如此，因为可能有很长的时间没有用户访问。但是，如果您正在执行关键任务，则应确保您的Hangfire Server实例始终运行，以确保即时后台处理。

内部应用程序
------------------------

对于在服务器上运行的Web应用程序（物理或虚拟），您需要使用版本高于2008的 Windows Server 附带的IIS≥7.5的自启功能。完整设置需要完成以下步骤：

1. 允许 Windows Process Activation (WAS) 和 World Wide Web Publishing (W3SVC) 服务自启（默认自启）。
2. 允许应用程序池 `配置自启 <http://technet.microsoft.com/en-us/library/cc772112(v=ws.10).aspx>`_ (默认开启)。
3. 启用应用程序池的始终运行模式，并配置自启功能，如下所示。

创建几个类
~~~~~~~~~~~~~~~~~

首先，您需要一个实现 ``IProcessHostPreloadClient`` 接口的特殊类。 它将会随着 Windows Process Activation 服务启动、每个应用程序池回收之后自动调用。

.. code-block:: c#

   public class ApplicationPreload : System.Web.Hosting.IProcessHostPreloadClient
   {
       public void Preload(string[] parameters)
       {
           HangfireBootstrapper.Instance.Start();
       }
   }

然后， 如下所述更新您的 ``global.asax.cs`` 文件。 :doc:`关键 <../background-processing/processing-background-jobs>` 是记得为 ``BackgroundJobServer`` 的实例调用 ``Stop`` 方法。 同时启动Hangfire server，即使在没有自启功能的环境（如开发环境）中。

.. code-block:: c#

    public class Global : HttpApplication
    {
        protected void Application_Start(object sender, EventArgs e)
        {
            HangfireBootstrapper.Instance.Start();
        }
 
        protected void Application_End(object sender, EventArgs e)
        {
            HangfireBootstrapper.Instance.Stop();
        }
    }

接着, 如下创建 ``HangfireBootstrapper`` 类。 即使 ``Application_Start`` 和 ``Preload`` 方法将在自启的环境中被调用，也需要确保初始化逻辑将被调用一次。

.. code-block:: c#

    public class HangfireBootstrapper : IRegisteredObject
    {
        public static readonly HangfireBootstrapper Instance = new HangfireBootstrapper();

        private readonly object _lockObject = new object();
        private bool _started;

        private BackgroundJobServer _backgroundJobServer;
        
        private HangfireBootstrapper()
        {
        }
        
        public void Start()
        {
            lock (_lockObject)
            {
                if (_started) return;
                _started = true;

                HostingEnvironment.RegisterObject(this);

                GlobalConfiguration.Configuration
                    .UseSqlServerStorage("connection string");
                    // Specify other options here

                _backgroundJobServer = new BackgroundJobServer();
            }
        }

        public void Stop()
        {
            lock (_lockObject)
            {
                if (_backgroundJobServer != null)
                {
                    _backgroundJobServer.Dispose();
                }

                HostingEnvironment.UnregisterObject(this);
            }
        }

        void IRegisteredObject.Stop(bool immediate)
        {
            Stop();
        }
    }

另外, 如果想要启用 Hangfire Dashboard UI, 请创建一个 OWIN startup 类:

.. code-block:: c#

   public class Startup
   {
       public void Configuration(IAppBuilder app)
       {
	       var options = new DashboardOptions
		   {
               AuthorizationFilters = new[]
               {
                   new LocalRequestsOnlyAuthorizationFilter()
               }
		   };

           app.UseHangfireDashboard("/hangfire", options);
       }
   }

启用服务自动启动
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

创建上述类后，您应该编辑全局的 ``applicationHost.config`` 文件 (``%WINDIR%\System32\inetsrv\config\applicationHost.config``)。首先，您需要将应用程序池的启动模式更改为 ``AlwaysRunning`` 模式，然后启用 Service AutoStart Providers。

.. admonition:: 记得保存所有的修改
   :class: note

   进行这些更改后，相应的应用程序池将自动重新启动。**只有** 在确保所有元素 **修改后** 才保存更改。

.. code-block:: xml

   <applicationPools>
       <add name="MyAppWorkerProcess" managedRuntimeVersion="v4.0" startMode="AlwaysRunning" />
   </applicationPools>

   <!-- ... -->

   <sites>
       <site name="MySite" id="1">
           <application path="/" serviceAutoStartEnabled="true" 
                                 serviceAutoStartProvider="ApplicationPreload" />
       </site>
   </sites>

   <!-- Just AFTER closing the `sites` element AND AFTER `webLimits` tag -->
   <serviceAutoStartProviders>
       <add name="ApplicationPreload" type="WebApplication1.ApplicationPreload, WebApplication1" />
   </serviceAutoStartProviders>

请注意最后一项， ``WebApplication1.ApplicationPreload`` 在程序中是类的全名，并且 ``IProcessHostPreloadClient`` 和 ``WebApplication1`` 是应用程序库的名称。 更多资料请参阅 `这里 <http://www.asp.net/whitepapers/aspnet4#0.2__Toc253429241>`_ 。
 
没有必要将IdleTimeout设置为零 -- 当应用程序池的启动模式设置为 ``AlwaysRunning``, idle timeout 将失去作用。

确保自启功能正在工作
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. admonition:: 如果出现问题...
   :class: note

   如果您的应用程序在进行这些更改后无法加载，请通过打开 **控制面板** → **管理工具** → **事件查看器来检查Windows事件日志** 。然后通过 *Windows日志 → 应用程序* 查找最新的错误记录。

最简单的检查方法  - 回收您的应用程序池，5分钟后转到Hangfire 仪表盘并检查当前的 Hangfire Server 实例是否在5分钟前启动。如果您有问题 - 请不要犹豫，在 `论坛上 <http://discuss.hangfire.io>`_ 提问。

Azure Web应用程序
-----------------------

在 Microsoft Azure 启用应用程序始终运行的功能更简单: 只需打开配置页面上的 ``Always On`` 的开关并保存。

此设置不适用于免费网站。

.. image:: always-on.png
   :alt: Always On switch

如果不适用... 
--------------------------

… 正在使用共享托管，免费Azure网站或其他 (顺便问一句，您可以在这种情况下告诉我您的配置？), 那么您可以使用以下方式确保Hangfire Server始终运行：

1. 使用 :doc:`独立的进程 <../background-processing/placing-processing-into-another-process>`  来处理相同或专用主机上的后台任务。
2. 通过外部工具（如, `Pingdom <https://www.pingdom.com/>`_)定期向您的网站发送HTTP请求。
3. *还有别的方法? 请告诉我!*
