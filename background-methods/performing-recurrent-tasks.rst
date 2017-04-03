执行周期性任务
===========================

执行周期性任务也是一样简单，您只需要编写一行代码：

.. code-block:: c#

   RecurringJob.AddOrUpdate(() => Console.Write("Easy!"), Cron.Daily);

此行在持久存储中创建一个新实体。 Hangfire Server中的一个特殊组件(请参阅 :doc:`../background-processing/processing-background-jobs`) 以分钟为间隔检查周期性任务，然后在队列中将其视作 fire-and-forget 任务。这样就可以照常跟踪它们。

.. admonition:: 确保您的应用程序始终运行
   :class: warning

   您的Hangfire Server实例应始终运行，并执行任务调度和处理逻辑。如果您在ASP.NET应用程序中执行处理，还请阅读 :doc:`../deployment-to-production/making-aspnet-app-always-running` 一章。

``Cron`` 类包含不同的方法和重载，以分钟，小时，每天，每周，每月和每年的方式运行任务。您还可以使用 `CRON 表达式 <http://en.wikipedia.org/wiki/Cron#CRON_expression>`_ 来执行更复杂的计划：

.. code-block:: c#

   RecurringJob.AddOrUpdate(() => Console.Write("Powerful!"), "0 12 * */2");

指定标识符
-----------------------

每个循环作业都有自己的唯一标识符。在前面的例子中，它使用调用的表达式的类型和方法名称 (导致 ``"Console.Write"`` 作为标识符)隐式生成。  ``RecurringJob`` 类包含一个明确定义的任务标识符重载，所以你可以参考下面这个例子。

.. code-block:: c#

   RecurringJob.AddOrUpdate("some-id", () => Console.WriteLine(), Cron.Hourly);

调用 ``AddOrUpdate`` 方法将创建一个新的循环作业或更新具有相同标识符的现有任务。

.. admonition:: 标识符应该是唯一的
   :class: warning

   对每个周期任务使用唯一的标识符，否则您将以单个作业结束。

.. admonition:: 标识符可能区分大小写
   :class: note

   在一些存储实现中，重复的作业标识符可能 **区分大小写**。

操作周期任务
----------------------------

您可以通过调用 ``RemoveIfExists`` 方法来删除现有的周期任务。当不存在该周期工作时，它不会抛出异常。

.. code-block:: c#

   RecurringJob.RemoveIfExists("some-id");

要立即执行周期任务，请调用 ``Trigger`` 方法。关于触发调用的信息不会记录在周期任务，并且不会改变下一次执行任务的时间。例如，如果有一周每周三触发的任务，当你在周五手动触发时，下一次触发的时间还是下周三。

.. code-block:: c#

   RecurringJob.Trigger("some-id");

 ``RecurringJob``类是 ``RecurringJobManager`` 类的一个入口。如果您想要更多的权力和责任，请考虑使用它：

.. code-block:: c#

   var manager = new RecurringJobManager();
   manager.AddOrUpdate("some-id", Job.FromExpression(() => Method()), Cron.Yearly);
