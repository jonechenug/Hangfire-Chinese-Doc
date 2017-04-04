处理后台任务
===========================

*Hangfire Server* 负责处理后台任务。Hangfire Server 不依赖于ASP.NET，可以从任何应用中启动，从控制台应用程序到Microsoft Azure Worker Role。所有应用程序的单一API通过 ``BackgroundJobServer`` 类公开：

.. code-block:: c#

   // 创建一个Hangfire Server实例并启动它。
   // 请查看高级选项 
   // 显式实现任务存储的实例
   var server = new BackgroundJobServer(); 
   
   // 等待服务器正常关机。
   server.Dispose();

.. admonition:: 始终释放您的后台任务服务器
   :class: warning

   尽可能调用 ``Dispose`` 方法以便正常地关闭服务器。

Hangfire Server 由不同的组件组成，负责不同的工作: workers 监听队列和处理任务, recurring scheduler 入队周期任务, schedule poller 入队延迟任务, expire manager 删除过时的任务并保持存储尽可能干净。

.. admonition:: 您可以不处理
   :class: note

   如果您不想在特定应用程序实例中处理后台作业，请不要创建 ``BackgroundJobServer`` 的实例。

``Dispose`` 是一个 **阻塞** 的方法，它会等到所有组件就绪(例如，worker 还在将中断的任务置于队列中)后关闭 。所以我们可以在等待所有的组件就绪后关闭服务器。

严格来说，您不需要调用 ``Dispose`` 方法。Hangfire甚至可以处理意外的进程终止，并将自动重试中断的任务。但是最好通过使用 :doc:`取消令牌 <../background-methods/using-cancellation-tokens>` 来取消任务。