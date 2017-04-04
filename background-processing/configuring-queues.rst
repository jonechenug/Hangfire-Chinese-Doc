
配置任务队列
======================

Hangfire可以处理多个队列。如果您要优先处理作业或按服务实例分割(一些处理存档的队列, 其他处理镜像队列等),则可以告知Hangfire处理。

要将任务放入不同的队列中， 在你的方法中使用 QueueAttribute 类:

.. code-block:: c#

   [Queue("critical")]
   public void SomeMethod() { }

   BackgroundJob.Enqueue(() => SomeMethod());
  
.. admonition:: 队列名称的格式
   :class: warning

   队列名称参数必须由小写字母，数字和下划线字符组成。
  
要处理多个队列，您需要更新 ``BackgroundJobServer`` 的配置。

.. code-block:: c#

   var options = new BackgroundJobServerOptions 
   {
       Queues = new[] { "critical", "default" }
   };
   
   app.UseHangfireServer(options);
   // or
   using (new BackgroundJobServer(options)) { /* ... */ }

顺序很重要，worker将首先从critical队列中获取任务，然后从default 队列中获取任务。
