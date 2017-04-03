调用延时方法
===========================

有时你可能想推迟调用一个方法;例如，在注册后的一天向新注册的用户发送电子邮件。要做到这一点，只需调用 ``BackgroundJob.Schedule`` 方法并传递所需的时间跨度：

.. code-block:: c#

   BackgroundJob.Schedule(
       () => Console.WriteLine("Hello, world"),
       TimeSpan.FromDays(1));

:doc:`Hangfire Server <../background-processing/processing-background-jobs>` 定期检查计划任务并将其入队,并允许worker执行。默认情况下，检查的间隔时间是 ``15 秒``, 但您可以更改它，只需将相应的选项传递给 ``BackgroundJobServer`` 的构造器。

.. code-block:: c#

  var options = new BackgroundJobServerOptions
  {
      SchedulePollingInterval = TimeSpan.FromMinutes(1)
  };

  var server = new BackgroundJobServer(options);

如果您正在ASP.NET应用程序中处理您的任务，某些设置可能会阻止您的任务如期执行。要避免此行为，请执行以下步骤：

* `禁用空闲超时  <http://bradkingsley.com/iis7-application-pool-idle-time-out-settings/>`_ – 将其值设置为 ``0``。
* 使用 `application auto-start <http://weblogs.asp.net/scottgu/auto-start-asp-net-applications-vs-2010-and-net-4-0-series>`_ 功能。
