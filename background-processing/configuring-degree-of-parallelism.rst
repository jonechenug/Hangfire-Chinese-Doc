配置并行数
======================================

后台任务由在Hangfire Server的子系统中运行的专用工作线程池进行处理。当您启动后台任务服务器时，它将初始化线程池并启动固定的worker。您可以通过将值传递给 ``UseHangfireServer`` 方法来指定并行数。

.. code-block:: c#

   var options = new BackgroundJobServerOptions { WorkerCount = Environment.ProcessorCount * 5 };
   app.UseHangfireServer(options);
   
如果您在Windows服务或控制台应用程序中使用Hangfire，只需执行以下操作：

.. code-block:: c#

    var options = new BackgroundJobServerOptions
    {
        // 这是默认值
        WorkerCount = Environment.ProcessorCount * 5
    };

    var server = new BackgroundJobServer(options);

Worker池使用专用线程来处理单独的请求，以便您手动配置并行度，处理CPU密集型或I/O密集型任务。
