使用批量任务
==============

.. admonition:: 仅支持Pro
   :class: note

   此功能是 `Hangfire Pro <http://hangfire.io/pro/>`_ 软件包的一部分。

批量任务允许您创建了一堆 *原子性* 的后台任务。这意味着如果在创建后台任务时出现异常，不会处理这些异常。假设你想要发送1000封电子邮件给你的客户，旧的方法是：

.. code-block:: c#

   for (var i = 0; i < 1000; i++)
   {
       BackgroundJob.Enqueue(() => SendEmail(i));
       // What to do on exception?
   }

但是如果任务存储在 ``中途`` 不可用呢？可能已经发送了500封电子邮件，因为工作线程创建后将会接收和处理任务。如果您重新执行此代码，您的某些客户可能会收到烦人的重复邮件。所以如果你想正确处理这个问题，你应该编写更多的代码来跟踪电子邮件的发送情况。

但这里有一个简单的方法:

.. code-block:: c#

   BatchJob.StartNew(x =>
   {
       for (var i = 0; i < 1000; i++)
       {
           x.Enqueue(() => SendEmail(i));
       }
   });

万一有异常，您可能会向用户显示错误，几分钟后重试。不需要其他代码！

安装
-------------

批量任务来自 `Hangfire.Pro <http://nuget.hangfire.io/feeds/hangfire-pro/Hangfire.Pro/>`_ 的软件包,您可以使用NuGet软件包管理器控制台窗口进行安装：

.. code-block:: powershell

   PM> Install-Package Hangfire.Pro

执行批量任务需要添加一些过滤器，一些新页面到仪表板，以及一些新的导航菜单项。幸亏在 ``GlobalConfiguration`` 类中只需简单地调用方法：

.. code-block:: c#

   GlobalConfiguration.Configuration.UseBatches();

.. admonition:: 有限的存储支持
   :class: warning

   目前仅支持 **Hangfire.SqlServer** 和 **Hangfire.Pro.Redis** 任务存储。批量任务没有什么特别之处，但需要实现一些新的存储方法。

链式批量任务
-----------------

允许您将多个批量任务连在一起执行。一旦 *所有父任务* 完成，将执行子任务。回到之前的示例，您有1000个电子邮件发送。如果发送邮件后执行别的操作，只需继续添加任务：

.. code-block:: c#

   var id1 = BatchJob.StartNew(/* for (var i = 0; i < 1000... */);
   var id2 = BatchJob.ContinueWith(id, x => 
   {
       x.Enqueue(() => MarkCampaignFinished());
       x.Enqueue(() => NotifyAdministrator());
   });

因此，批量任务和链式批量任务允许您定义工作流和并行操作。这对于密集型计算非常有用，因为它们可以分配到不同的机器。

复杂的工作流程
------------------

不限制您仅在入队状态下创建任务。您可以在延迟任务中继续添加后续的操作。

.. code-block:: c#

   var batchId = BatchJob.StartNew(x =>
   {
       x.Enqueue(() => Console.Write("1a... "));
       var id1 = x.Schedule(() => Console.Write("1b... "), TimeSpan.FromSeconds(1));
       var id2 = x.ContinueWith(id1, () => Console.Write("2... "));
       x.ContinueWith(id2, () => Console.Write("3... "));
   });
   
   BatchJob.ContinueWith(batchId, x =>
   {
       x.Enqueue(() => Console.WriteLine("4..."));
   });