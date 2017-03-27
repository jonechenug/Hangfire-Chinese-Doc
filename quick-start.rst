快速开始
============

安装
-------------

在nuget上有关于Hangfire的 `一系列软件包
<https://www.nuget.org/packages?q=Hangfire>`_ 。 要使用 **SQL Server** 存储将Hangfire安装到 **ASP.NET 应用程序** 中，请在Package Manager Console窗口中键入以下命令：

.. code-block:: powershell

   PM> Install-Package Hangfire

配置
--------------

安装软件包后，在OWIN启动类添加或更新如以下几行：

.. code-block:: c#

   using Hangfire;

   // ...

   public void Configuration(IAppBuilder app)
   {
       GlobalConfiguration.Configuration.UseSqlServerStorage("<connection string or its name>");

       app.UseHangfireDashboard();
       app.UseHangfireServer();
   }

.. admonition:: 请配置授权
   :class: warning

   默认情况下，只有本地访问权限才能使用Hangfire仪表板。为了远程访问必须配置 `仪表板授权 <configuration/using-dashboard.html#configuring-authorization>`__ 。

然后打开Hangfire仪表板来测试您的配置。请构建项目并在浏览器中打开以下URL：

.. raw:: html

   <div style="border-radius: 0;border:solid 3px #ccc;background-color:#fcfcfc;box-shadow: 1px 1px 1px #ddd inset, 1px 1px 1px #eee;padding:3px 7px;margin-bottom: 10px;">
       <span style="color: #666;">http://&lt;your-site&gt;</span>/hangfire
   </div>


.. image:: http://hangfire.io/img/ui/dashboard-sm.png

用法
------

新增一个任务…
~~~~~~~~~~~

Hangfire处理不同类型的后台作业， 并且每个任务都在单独的执行上下文中被调用。

Fire-and-forget
^^^^^^^^^^^^^^^^

这是主要的后台作业类型，在持久化的消息队列中处理。一旦你创建一个 fire-and-forget 任务, 它将被加入到队列 (默认为"default"，除此之外也支持多个队列)中。 该队列将被指定的消费者监听并执行。

.. code-block:: c#
   
   BackgroundJob.Enqueue(() => Console.WriteLine("Fire-and-forget"));

Delayed
^^^^^^^^

如果要延迟某种类型的方法调用，请调用以下方法。在指定的延迟时间之后，工作将被放置到队列中，作为常规的 fire-and-forget 类型的任务处理。 

.. code-block:: c#

   BackgroundJob.Schedule(() => Console.WriteLine("Delayed"), TimeSpan.FromDays(1));

Recurring
^^^^^^^^^^

要按照周期性（小时，每天等）调用方法，请使用 ``RecurringJob`` 类调用。您可以使用 `CRON 表达式 <http://en.wikipedia.org/wiki/Cron#CRON_expression>`_ 来处理更复杂的使用场景。

.. code-block:: c#

   RecurringJob.AddOrUpdate(() => Console.WriteLine("Daily Job"), Cron.Daily);

Continuations
^^^^^^^^^^^^^^

Continuations 允许您通过将多个后台作业结合起来定义复杂的工作流。

.. code-block:: c#

   var id = BackgroundJob.Enqueue(() => Console.WriteLine("Hello, "));
   BackgroundJob.ContinueWith(id, () => Console.WriteLine("world!"));

… 请放心
~~~~~~~~~~~~

Hangfire将您的工作保存到持久存储中，并以可靠的方式处理它们。这意味着在您中止Hangfire工作线程，卸载应用程序域，甚至终止进程， 你的任务仍会保存起来等待处理 [#note]_. Hangfire在你执行完任务的代码之前都标记状态，包括可能失败的任务状态。它包含不同的自动重试功能，存储错误的信息。

这对于通用托管环境（如IIS Server）非常重要。可以通过 `特定的、超时、错误处理的策略
<https://github.com/odinserj/Hangfire/wiki/IIS-Can-Kill-Your-Threads>`_ 终止进程来避免错误发生。如果您没有使用可靠的处理和自动重试，您的任务可能会丢失。 这样,你的客户因此等不到 email, 被告和通知 等等。

.. [#] 但是当您的存储空间破损时，Hangfire无法做任何事情。请为您的存储使用不同的故障切换策略，以保证在发生灾难时处理每个作业。
