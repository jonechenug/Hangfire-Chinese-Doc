使用取消令牌
===========================

Hangfire在发起一个取消任务请求或者终止任务时，为任务提供了取消令牌的支持，在前一种情况下，将自动放回队列的对头，允许Hangfire重新处理任务。

取消令牌通过 ``IJobCancellationToken`` 的接口暴露出来。当发起取消任务请求时，它通过 ``ThrowIfCancellationRequested`` 方法来抛出 ``OperationCanceledException`` :

.. code-block:: c#

   public void LongRunningMethod(IJobCancellationToken cancellationToken)
   {
       for (var i = 0; i < Int32.MaxValue; i++)
       {
           cancellationToken.ThrowIfCancellationRequested();

           Thread.Sleep(TimeSpan.FromSeconds(1));
       }
   }

当您要将这种调用方法作为后台任务入队时，您可以将 ``null`` 值作为token参数的参数传递，或者使用 ``JobCancellationToken.Null`` 属性：

.. code-block:: c#

   BackgroundJob.Enqueue(() => LongRunningMethod(JobCancellationToken.Null));
   
.. admonition:: 自动触发
   :class: note

   Hangfire在任务执行期间时刻关注着 ``IJobCancellationToken`` 的非空实例。

您应该尽可能使用取消令牌 – 它们大大降低了应用程序关闭时和出现的 ``ThreadAbortException`` 风险。
