调用延时方法
===========================

有时你可能想推迟调用一个方法;例如，在注册后的一天向新注册的用户发送电子邮件。要做到这一点，只需调用 ``BackgroundJob.Schedule`` 方法并传递所需的时间跨度：

.. code-block:: c#

   BackgroundJob.Schedule(
       () => Console.WriteLine("Hello, world"),
       TimeSpan.FromDays(1));

:doc:`Hangfire Server <../background-processing/processing-background-jobs>` 定期检查计划任务并将其入队, allowing workers to perform them. By default, check interval is equal to ``15 seconds``, but you can change it, just pass the corresponding option to the ``BackgroundJobServer`` ctor.

.. code-block:: c#

  var options = new BackgroundJobServerOptions
  {
      SchedulePollingInterval = TimeSpan.FromMinutes(1)
  };

  var server = new BackgroundJobServer(options);

If you are processing your jobs inside an ASP.NET application, you should be warned about some setting that may prevent your scheduled jobs to be performed in-time. To avoid that behavior, perform the following steps:

* `Disable Idle Timeout <http://bradkingsley.com/iis7-application-pool-idle-time-out-settings/>`_ – set its value to ``0``.
* Use the `application auto-start <http://weblogs.asp.net/scottgu/auto-start-asp-net-applications-vs-2010-and-net-4-0-series>`_ feature.
