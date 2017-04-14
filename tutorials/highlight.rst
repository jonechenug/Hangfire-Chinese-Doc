语法高亮教程
=========================

====================== =======
简单示例                https://github.com/odinserj/Hangfire.Highlighter 
完整示例                http://highlighter.hangfire.io, `sources <https://github.com/odinserj/Hangfire/tree/master/samples/Hangfire.Sample.Highlighter>`_
====================== =======

.. contents:: Table of Contents
   :local:
   :depth: 2

概述
---------

假设您正在构建一个代码仓库的Web应用程序，如 `GitHub Gists <http://gist.github.com>`_, 并希望实现语法高亮显示的功能。为了提高用户体验，即使用户在浏览器中禁用了JavaScript，您也希望它能够正常工作。

为了实现功能并减少项目开发时间，选择使用Web服务进行语法高亮，就像 http://pygments.appspot.com 或 http://www.hilite.me。

.. note::

   虽然此功能可以在没有Web服务的情况下实现 (为.NET使用其他的语法高亮库),我们只是为了展示在web应用程序中存在的某些缺陷。

   您可以将此示例替换为真实场景，例如使用外部SMTP服务、其他服务，甚至长时间运行的CPU密集型任务。

配置项目
-----------------------

.. tip::

   本节包含项目准备的步骤。但是如果您不想做无聊的事情，或者如果您在配置项目上有问题, 可以下载教程 `源码 <https://github.com/odinserj/Hangfire.Highlighter/releases/tag/vBefore>`_ ，直接转到 :ref:`the-problem` 一节.

先决条件
^^^^^^^^^^^^^^

本教程使用带 `Web Tools 2013 for Visual Studio 2012 <http://www.asp.net/visual-studio/overview/2012/aspnet-and-web-tools-20131-for-visual-studio-2012>`_ 扩展的 **Visual Studio 2012** , 也可以使用 Visual Studio 2013 构建。

本项目使用 **.NET 4.5**、 **ASP.NET MVC 5** 和 **SQL Server 2008 Express** 或更高版本的数据库。

创建项目
^^^^^^^^^^^^^^^^^^^

从零开始，创建一个 *ASP.NET MVC 5 空项目* ，并命名这个Web应用程序为 ``Hangfire.Highlighter`` (可以按需要命名，但记得更改命名空间)。

我已经截取一些屏幕截图，使配置项目不那么无聊：

.. image:: highlighter/newproj.png

然后,我们需要一个控制器来处理Web请求。搭建一个 **MVC 5 Controller - Empty** 控制器并命名为 ``HomeController``:

.. image:: highlighter/addcontrollername.png

我们的控制器现在只有 ``Index`` action ，看起来像:

.. code-block:: c#

   public class HomeController : Controller
   {
       public ActionResult Index()
       {
           return View();
       }
   }

我们现在只有一个 action 的单个控制器。为了测试我们的应用程序是否正常工作，为 ``Index`` action 新增一个 **empty view** 。

.. image:: highlighter/addview.png

添加视图脚手架的的过程中能够还向项目添加了额外的组件, 像是 *Bootstrap*, *jQuery*, 等。 在这些步骤之后，我的解决方案如下所示：

.. image:: highlighter/solutionafterview.png

我们来测试一下应用程序的初始化。按下 :kbd:`F5` 启动调试，等待你的浏览器跳转。如果遇到异常或没有看到默认页面，请尝试重现所有给定的步骤，请参阅 `本教程源码 <https://github.com/odinserj/Hangfire.Highlighter>`_ 或在下面评论中提出问题。

定义模型
~~~~~~~~~~~~~~~~

应用程序重新启动后，我们应该使用持久存储来保存代码。因此，我们将使用 **SQL Server 2008 Express** (或更高版本) 作为关系存储，并使用 **Entity Framework** 访问我们的应用程序的数据。

安装 Entity Framework
++++++++++++++++++++++++++++

打开 `Package Manager Console <https://docs.nuget.org/docs/start-here/using-the-package-manager-console>`_ 的窗口并输入：

.. code-block:: powershell

   Install-Package EntityFramework

安装软件包后，在 ``Models`` 文件夹中创建一个新类并命名为 ``HighlighterDbContext``:

.. code-block:: c#

   // ~/Models/HighlighterDbContext.cs

   using System.Data.Entity;

   namespace Hangfire.Highlighter.Models
   {
       public class HighlighterDbContext : DbContext
       {
           public HighlighterDbContext() : base("HighlighterDb")
           {
           }
       }
   }

请注意，我们使用命名为 ``HighlighterDb`` 的未定义连接字符串。 将它添加到 ``web.config`` 文件中的 ``</configSections>`` 标签之后:

.. code-block:: xml

   <connectionStrings>
     <add name="HighlighterDb" connectionString="Server=.\sqlexpress; Database=Hangfire.Highlighter; Trusted_Connection=True;" providerName="System.Data.SqlClient" />
   </connectionStrings>

启用 **Entity Framework Code First Migrations** ，需要在 *Package Manager Console* 窗口中输入如下命令:

.. code-block:: powershell

   Enable-Migrations

添加代码模型
++++++++++++++++++++++++++

现在需要在应用程序中添加最有价值的类，在 ``Models`` 文件夹中创建命名为 ``CodeSnippet`` 的类并添加如下代码:

.. code-block:: c#

   // ~/Models/CodeSnippet.cs

   using System;
   using System.ComponentModel.DataAnnotations;
   using System.Web.Mvc;

   namespace Hangfire.Highlighter.Models
   {
       public class CodeSnippet
       {
           public int Id { get; set; }

           [Required, AllowHtml, Display(Name = "C# source")]
           public string SourceCode { get; set; }
           public string HighlightedCode { get; set; }

           public DateTime CreatedAt { get; set; }
           public DateTime? HighlightedAt { get; set; }
       }
   }

不要忘记在命名为 ``HighlighterDbContext`` 类中包含以下属性:

.. code-block:: c#

   // ~/Models/HighlighterDbContext.cs
   public DbSet<CodeSnippet> CodeSnippets { get; set; }

然后添加数据库迁移，通过在包管理器控制台窗口中输入以下命令来运行它：

.. code-block:: powershell

   Add-Migration AddCodeSnippet
   Update-Database

我们的数据库已经可以使用了！

创建动作和视图
~~~~~~~~~~~~~~~~~~~~~~~~~~~

现在需要为我们的项目注入生命了，请按照上述说明修改以下文件。

.. code-block:: c#

  // ~/Controllers/HomeController.cs

  using System;
  using System.Linq;
  using System.Web.Mvc;
  using Hangfire.Highlighter.Models;

  namespace Hangfire.Highlighter.Controllers
  {
      public class HomeController : Controller
      {
          private readonly HighlighterDbContext _db = new HighlighterDbContext();

          public ActionResult Index()
          {
              return View(_db.CodeSnippets.ToList());
          }

          public ActionResult Details(int id)
          {
              var snippet = _db.CodeSnippets.Find(id);
              return View(snippet);
          }

          public ActionResult Create()
          {
              return View();
          }

          [HttpPost]
          public ActionResult Create([Bind(Include="SourceCode")] CodeSnippet snippet)
          {
              if (ModelState.IsValid)
              {
                  snippet.CreatedAt = DateTime.UtcNow;
                   
                  // We'll add the highlighting a bit later.

                  _db.CodeSnippets.Add(snippet);
                  _db.SaveChanges();

                  return RedirectToAction("Details", new { id = snippet.Id });
              }

              return View(snippet);
          }

          protected override void Dispose(bool disposing)
          {
              if (disposing)
              {
                  _db.Dispose();
              }
              base.Dispose(disposing);
          }
      }
  }

.. code-block:: html

  @* ~/Views/Home/Index.cshtml *@

  @model IEnumerable<Hangfire.Highlighter.Models.CodeSnippet>
  @{ ViewBag.Title = "Snippets"; }

  <h2>Snippets</h2>

  <p><a class="btn btn-primary" href="@Url.Action("Create")">Create Snippet</a></p>
  <table class="table">
      <tr>
          <th>Code</th>
          <th>Created At</th>
          <th>Highlighted At</th>
      </tr>

      @foreach (var item in Model)
      {
          <tr>
              <td>
                  <a href="@Url.Action("Details", new { id = item.Id })">@Html.Raw(item.HighlightedCode)</a>
              </td>
              <td>@item.CreatedAt</td>
              <td>@item.HighlightedAt</td>
          </tr>
       }
  </table>

.. code-block:: html

  @* ~/Views/Home/Create.cshtml *@

  @model Hangfire.Highlighter.Models.CodeSnippet
  @{ ViewBag.Title = "Create a snippet"; }

  <h2>Create a snippet</h2>

  @using (Html.BeginForm())
  {
      @Html.ValidationSummary(true)

      <div class="form-group">
          @Html.LabelFor(model => model.SourceCode)
          @Html.ValidationMessageFor(model => model.SourceCode)
          @Html.TextAreaFor(model => model.SourceCode, new { @class = "form-control", style = "min-height: 300px;", autofocus = "true" })
      </div>

      <button type="submit" class="btn btn-primary">Create</button>
      <a class="btn btn-default" href="@Url.Action("Index")">Back to List</a>
  }

.. code-block:: html

  @* ~/Views/Home/Details.cshtml *@

  @model Hangfire.Highlighter.Models.CodeSnippet
  @{ ViewBag.Title = "Details"; }

  <h2>Snippet <small>#@Model.Id</small></h2>

  <div>
      <dl class="dl-horizontal">
          <dt>@Html.DisplayNameFor(model => model.CreatedAt)</dt>
          <dd>@Html.DisplayFor(model => model.CreatedAt)</dd>
          <dt>@Html.DisplayNameFor(model => model.HighlightedAt)</dt>
          <dd>@Html.DisplayFor(model => model.HighlightedAt)</dd>
      </dl>
      
      <div class="clearfix"></div>
  </div>

  <div>@Html.Raw(Model.HighlightedCode)</div>

添加 MiniProfiler
~~~~~~~~~~~~~~~~~~~~

不想动眼观察应用, 我们将使用NuGet上提供的 ``MiniProfiler`` 软件包。

.. code-block:: c#

  Install-Package MiniProfiler

安装后，如下述更新文件，启用概要分析。

.. code-block:: c#

  // ~/Global.asax.cs

  public class MvcApplication : HttpApplication
  {
      /* ... */

      protected void Application_BeginRequest()
      {
          StackExchange.Profiling.MiniProfiler.Start();
      }

      protected void Application_EndRequest()
      {
          StackExchange.Profiling.MiniProfiler.Stop();
      }
  }

.. code-block:: html

  @* ~/Views/Shared/_Layout.cshtml *@

  <head>
    <!-- ... -->
    @StackExchange.Profiling.MiniProfiler.RenderIncludes()
  </head>

您还需要在 ``web.config`` 文件中包含以下配置, 如果在您的应用程序中 ``runAllManagedModulesForAllRequests`` 设置为 ``false`` （默认情况）:

.. code-block:: xml

  <!-- ~/web.config -->

  <configuration>
    ...
    <system.webServer>
      ...
      <handlers>
        <add name="MiniProfiler" path="mini-profiler-resources/*" verb="*" type="System.Web.Routing.UrlRoutingModule" resourceType="Unspecified" preCondition="integratedMode" />
      </handlers>
    </system.webServer>
  </configuration>

代码语法高亮
^^^^^^^^^^^^^^^^^^

这是我们应用程序的核心功能。 我们将使用提供 HTTP API 的 http://hilite.me 服务器来完成语法高亮的工作。要使用它的 API, 请安装 ``Microsoft.Net.Http`` 软件包:

.. code-block:: powershell

   Install-Package Microsoft.Net.Http

该库提供简单的异步API，用于发送HTTP请求和接收HTTP响应。 所以我们使用它来向 *hilite.me* 服务器发出 HTTP 请求：

.. code-block:: c#

  // ~/Controllers/HomeController.cs

  /* ... */

  public class HomeController
  {
      /* ... */

      private static async Task<string> HighlightSourceAsync(string source)
      {
          using (var client = new HttpClient())
          {
              var response = await client.PostAsync(
                  @"http://hilite.me/api",
                  new FormUrlEncodedContent(new Dictionary<string, string>
                  {
                      { "lexer", "c#" },
                      { "style", "vs" },
                      { "code", source }
                  }));

              response.EnsureSuccessStatusCode();

              return await response.Content.ReadAsStringAsync();
          }
      }

      private static string HighlightSource(string source)
      {
          // Microsoft.Net.Http does not provide synchronous API,
          // so we are using wrapper to perform a sync call.
          return RunSync(() => HighlightSourceAsync(source));
      }

      private static TResult RunSync<TResult>(Func<Task<TResult>> func)
      {
          return Task.Run<Task<TResult>>(func).Unwrap().GetAwaiter().GetResult();
      }
  }

然后在 ``HomeController.Create`` 方法中调用它。 

.. code-block:: c#

  // ~/Controllers/HomeController.cs

  [HttpPost]
  public ActionResult Create([Bind(Include = "SourceCode")] CodeSnippet snippet)
  {
      try
      {
          if (ModelState.IsValid)
          {
              snippet.CreatedAt = DateTime.UtcNow;

              using (StackExchange.Profiling.MiniProfiler.StepStatic("Service call"))
              {
                  snippet.HighlightedCode = HighlightSource(snippet.SourceCode);
                  snippet.HighlightedAt = DateTime.UtcNow;
              }

              _db.CodeSnippets.Add(snippet);
              _db.SaveChanges();

              return RedirectToAction("Details", new { id = snippet.Id });
          }
      }
      catch (HttpRequestException)
      {
          ModelState.AddModelError("", "Highlighting service returned error. Try again later.");
      }

      return View(snippet);
  }

.. _async-note:

.. note::

  我们正在使用同步控制器动作方法，尽管建议在 ASP.NET 处理网络请求逻辑中使用 `异步的方式 <http://www.asp.net/mvc/tutorials/mvc-4/using-asynchronous-methods-in-aspnet-mvc-4>`_ 。正如给定文章所述，异步操作大大增加了应用程序的 :abbr:`处理能力 (The maximum throughput a system can sustain, for a given workload, while maintaining an acceptable response time for each individual transaction. – from "Release It" book written by Michael T. Nygard)`, 但并没有助于提高 :abbr:`性能 (How fast the system processes a single transaction. – from "Release It" book written by Michael T. Nygard)` 。您可以使用 `示例应用程序 <http://highlighter.hangfire.io>`_ 自行测试 – 在使用单个请求的同步或异步操作中没有任何差异。

  此示例旨在向您展示与应用程序性能相关的问题。同步操作简化了教程。

.. _the-problem:

问题
------------

.. tip::

  您可以使用 `托管示例 <http://highlighter.hangfire.io>`_ 来查看发生了什么。

现在，当应用程序准备就绪时，尝试创建一些代码片段，从较小的代码片段开始。单击 :guilabel:`Create` 按钮后，您是否注意到一小段延迟？

在我的开发机器上，花了大约0.5s将我重定向到详细信息页面。但是我们通过 *MiniProfiler* 看看延迟的原因是什么：

.. image:: highlighter/smcodeprof.png

正如我们所看到的，请求 web 服务器是主要的问题。但是当我们尝试创建一个代码块时会发生什么？

.. image:: highlighter/mdcodeprof.png

最后来个大的:

.. image:: highlighter/lgcodeprof.png

当我们扩大我们的代码片段时，延迟越来越大。此外,考虑到语法高亮请求 web 服务器(不在您的控制中) 会有高负载,或者网络方面存在延迟问题，抑或繁重的 CPU 密集型任务而不是无法优化的网络请求。

您的用户将因为应用程序的无法响应和不正确的延迟而感到烦恼。

解决问题
------------------

解决这样的问题需要做什么呢？ `异步控制器操作 <http://www.asp.net/mvc/tutorials/mvc-4/using-asynchronous-methods-in-aspnet-mvc-4>`_ 就像我 :ref:`之前 <async-note>` 说的不会有任何帮助。您应该以某种方式Web服务调用，并在后台处理该请求。这里有一些方法可以做到这一点：

* **使用周期任务** 并在一段时间内扫描未高亮显示的代码片段。
* **使用任务队列** 您的应用程序将入队任务，并且一些外部工作线程将监听此队列的新任务。

太好了。但是这些技术有几个困难。前者要求我们设置一些检查间隔。较短的间隔可能滥用我们的数据库，间隔时间加长则会增加延迟。

后一种方式解决了这个问题，但又带来了另一个问题。队列应该持久吗？你需要多少 worker？如何协调？他们应该在ASP.NET应用程序或外部在Windows服务中工作？最后一个问题是ASP.NET应用程序中长时间运行的请求处理的痛点：

.. warning::

   **不要** 在ASP.NET应用程序中运行长时间运行的程序，除非他们可以在 **在任何指令中死亡** ，并且有机制可以重新运行它们。

   它们将在应用程序关闭时被简单地中止， 即使由于超时后调用 ``IRegisteredObject`` 接口而被回收。

太多问题？ 请放松, 你可以使用 `Hangfire <http://hangfire.io>`_ 。它基于 *持久性队列* ，在应用程序重新启动后重生。 使用 *可靠的消费* 来处理线程中止的意外，并包含 *协同逻辑* 处理多个工作线程。并且它使用起来很简单。

.. note::

   **您可以** 在ASP.NET应用程序中使用Hangfire处理长时间运行的任务 - 中止的任务将自动重新启动。

安装 Hangfire
^^^^^^^^^^^^^^^^^^^^

要安装 Hangfire，请在 Package Manager Console 窗口中运行以下命令：

.. code-block:: powershell

   Install-Package Hangfire

安装软件包后，使用以下代码行添加或更新OWIN启动类。

.. code-block:: c#

   public void Configuration(IAppBuilder app)
   {
       GlobalConfiguration.Configuration.UseSqlServerStorage("HighlighterDb");

       app.UseHangfireDashboard();
       app.UseHangfireServer();
   }

就这样。所有数据库表将在第一次启动时自动创建。

转到后台处理
^^^^^^^^^^^^^^^^^^^^^

首先，我们需要定义我们的后台任务调用方法，当工作线程捕捉语法高亮任务时，它将被调用。我们将在 ``HomeController`` 中简单的定义一个带 ``snippetId`` 参数的静态方法。

.. code-block:: c#

  // ~/Controllers/HomeController.cs

  /* ... Action methods ... */

  // Process a job
  public static void HighlightSnippet(int snippetId)
  {
      using (var db = new HighlighterDbContext())
      {
          var snippet = db.CodeSnippets.Find(snippetId);
          if (snippet == null) return;

          snippet.HighlightedCode = HighlightSource(snippet.SourceCode);
          snippet.HighlightedAt = DateTime.UtcNow;

          db.SaveChanges();
      }
  }

请注意，它不包含任何与Hangfire相关的功能的简单方法。它创建一个新 ``HighlighterDbContext`` 类的实例，查找所需的代码段并请求 Web 服务器。

然后，我们需要将这个方法的调用放在一个队列上。所以让我修改 ``Create`` 动作:

.. code-block:: c#

  // ~/Controllers/HomeController.cs

  [HttpPost]
  public ActionResult Create([Bind(Include = "SourceCode")] CodeSnippet snippet)
  {
      if (ModelState.IsValid)
      {
          snippet.CreatedAt = DateTime.UtcNow;

          _db.CodeSnippets.Add(snippet);
          _db.SaveChanges();

          using (StackExchange.Profiling.MiniProfiler.StepStatic("Job enqueue"))
          {
              // Enqueue a job
              BackgroundJob.Enqueue(() => HighlightSnippet(snippet.Id));
          }

          return RedirectToAction("Details", new { id = snippet.Id });
      }

      return View(snippet);
  }

就这样，尝试创建一些代码片段并查看时间（不要担心，如果您看到一个空白的页面，我稍后会介绍）：

.. image:: highlighter/jobprof.png

不错, 6ms vs ~2s 。但还有另一个问题。你有没有注意到，有时没有被重定向到源代码的页面？这是因为我们的视图包含以下行：

.. code-block:: html
  
   <div>@Html.Raw(Model.HighlightedCode)</div>

为什么 ``Model.HighlightedCode`` 返回null而不是突出显示的代码？ 出现这种情况的一个 **潜在** 原因是刚好在调用后台任务 – 在一个worker 提取任务并处理它时会有一些延迟。您可以刷新页面，代码高亮将显示在屏幕上。

但空白页可能会混淆用户，该怎么办？首先，你需要具体到一个方面。您可以将延迟降至最低，但 **您无法避免**。所以，你的应用程序应该处理这个具体问题。

在我们的示例中，我们将简单地在代码未高亮的情况下出示告知，如果高亮了就不出示了：

.. code-block:: html

  @* ~/Views/Home/Details.cshtml *@

  <div>
      @if (Model.HighlightedCode == null)
      {
          <div class="alert alert-info">
              <h4>Highlighted code is not available yet.</h4>
              <p>Don't worry, it will be highlighted even in case of a disaster 
                  (if we implement failover strategies for our job storage).</p>
              <p><a href="javascript:window.location.reload()">Reload the page</a> 
                  manually to ensure your code is highlighted.</p>
          </div>
          
          @Model.SourceCode
      }
      else
      {
          @Html.Raw(Model.HighlightedCode)
      }
  </div>

但是，您可以使用 AJAX 轮询您的应用程序，直到返回高亮的代码：

.. code-block:: c#

   // ~/Controllers/HomeController.cs

   public ActionResult HighlightedCode(int snippetId)
   {
       var snippet = _db.Snippets.Find(snippetId);
       if (snippet.HighlightedCode == null)
       {
           return new HttpStatusCodeResult(HttpStatusCode.NoContent);
       }

       return Content(snippet.HighlightedCode);
   }

或者您还可以通过 SignalR调用 ``HighlightSnippet`` 方法向用户发出命令。但这是另一件事了。

.. note::

   请注意，用户仍然等待代码被高亮。但应用程序本身提高了可用性，并且他能够在处理后台任务时做另外一件事情。

结论
-----------

在本教程中，您已经看到：

* 有时您无法避免在 ASP.NET 应用程序中调用长期运行的方法。
* 长时间运行的方法可能会导致您的应用程序对于用户来说是不可靠的。
* 要避免等待，您应该将长时间运行的方法调用到后台任务中。
* 后台任务本身很复杂，但是使用Hangfire简单。
* 即使在具有 Hangfire 的 ASP.NET 应用程序中也可以处理后台任务。

请使用下面的评论提出任何问题。
