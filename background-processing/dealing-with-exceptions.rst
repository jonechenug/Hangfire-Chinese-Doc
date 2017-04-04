处理异常
========================

任何方法都可以抛出不同类型的异常。这些异常可能是需要应用程序重新部署来解决的编程错误，或者是不需要重新部署但可以解决的暂时性错误。

Hangfire可以处理所有内部的(属于Hangfire本身)和相关的外部方法(任务，过滤器等)的异常,因此不会导致整个应用程序被关闭。所有内部异常都被记录(所以不要忘记 :doc:`启用日志 <../configuration/configuring-logging>`)，最糟糕的情况是导致后台任务被暂停并延时重试 ``10`` 次。

当Hangfire遇到在执行期间发生的外部异常时，它将自动 *重试* 将其状态更改为 ``Failed`` 状态, 但您始终可以在 Monitor UI 中找到该任务(除非您明确删除，否则不会过期)。

.. image:: failed-job.png

上面讲过Hangfire通过 *重试* 将任务状态改为失败，因为该状态将被 :doc:`任务过滤器 <../extensibility/using-job-filters>` 拦截并重新初始化。其中 ``AutomaticRetryAttribute`` 可以安排失败的任务自动重试。

默认情况下该过滤器全局应用于所有方法，进行10次重试尝试。因此如果出现异常，您的方法将被重试，并且每次尝试失败时都会收到警告的日志消息。如果重试尝试超过其最大值，则任务将被标记为 ``Failed`` 状态 (包含错误日志信息),同时您也可以手动重试。

如果您不想要重试一个任务，请设置属性，将其最大重试次数设置为0：

.. code-block:: c#

   [AutomaticRetry(Attempts = 0)]
   public void BackgroundMethod()
   {   
   }

使用相同的方式可以将尝试次数限制为不同的值。如果要更改默认全局值，请添加新的全局过滤器：

.. code-block:: c#

   GlobalJobFilters.Filters.Add(new AutomaticRetryAttribute { Attempts = 5 });
