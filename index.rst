文档
==============

.. raw:: html
   :file: jumbotron.html

概述
---------

Hangfire允许您以非常简单但可靠的方式在请求管道之外启动方法调用。 这种 *后台线程* 中执行方法的行为称为 *后台任务*。

从高处看，它是由:*客户端*、*作业存储*、*服务端* 组成的。下图描述了Hangfire的主要组织：

.. image:: hangfire-workflow.png
   :alt: Hangfire Workflow
   :align: center
   

要求
-------------

Hangfire不受特定.NET应用程序类型的限制。您可以在 :doc:`ASP.NET Web应用程序 <background-processing/processing-jobs-in-web-app>` 、非ASP.NET Web应用程序、:doc:`控制台应用程序 <background-processing/processing-jobs-in-console-app>` 或 :doc:`Windows服务 <background-processing/processing-jobs-in-windows-service>` 中使用它。以下是要求：


* .NET Framework 4.5
* 持久存储（如下所示）
* `Newtonsoft.Json <https://www.nuget.org/packages/Newtonsoft.Json/>`_ library ≥ 5.0.1

客户端
-------

您可以使用Hangfire创建任何类型的后台作业： :doc:`fire-and-forget <../background-methods/calling-methods-in-background>` (自助调用), :doc:`delayed <../background-methods/calling-methods-with-delay>` (在一段时间后执行调用)、 :doc:`recurring <../background-methods/performing-recurrent-tasks>` (按小时，每天执行方法等)。
Hangfire不需要你创建特殊的课程。这些后台作业调用常规静态方法或实例方法。

.. code-block:: c#

   var client = new BackgroundJobClient();

   client.Enqueue(() => Console.WriteLine("Easy!"));
   client.Delay(() => Console.WriteLine("Reliable!"), TimeSpan.FromDays(1));

还有更简单的方法来创建后台作业， ``BackgroundJob`` 类允许您使用静态方法创建任务。

.. code-block:: c#

   BackgroundJob.Enqueue(() => Console.WriteLine("Hello!"));

在Hangfire序列化任务并保存到 *作业存储* 后将控制权转移给某个消费者。

作业存储
------------

Hangfire将后台任务及相关的其他信息保存到 *持久库*。持久化让后台作业在 **应用程序重新启动** 或服务器重启等情况下 **幸存**。这是使用 *CLR的线程池* 和 *Hangfire* 执行后台作业的主要区别。 支持多种存储:

* :doc:`SQL Azure, SQL Server 2008 R2 <../configuration/using-sql-server>` (以及更新的版本，包括 Express)
* :doc:`Redis <../configuration/using-redis>`

SQL Server存储可以通过 :doc:`MSMQ <../configuration/using-sql-server-with-msmq>` 或RabbitMQ授权来降低处理延迟。

.. code-block:: c#

   GlobalConfiguration.Configuration.UseSqlServerStorage("db_connection");

服务端
-------

后台任务由 :doc:`Hangfire Server <../background-processing/processing-background-jobs>` 处理。它实现一组专用（非线程池的）后台线程，用于从作业存储中取出任务并处理，服务端还负责自动删除旧数据以保持作业存储干净。

你只需是创建一个 ``BackgroundJobServer`` 类的实例并开始处理：

.. code-block:: c#

   using (new BackgroundJobServer())
   {
       Console.WriteLine("Hangfire Server started. Press ENTER to exit...");
       Console.ReadLine();
   }

Hangfire为任何一个作业存储使用可靠的处理算法，因此您可以内置在Web应用程序中处理，而不会担心在应用程序重新启动，进程终止等情况下丢失后台任务。

Table of Contents
------------------

.. toctree::
   :maxdepth: 2

   quick-start
   installation
   configuration/index
   background-methods/index
   background-processing/index
   best-practices
   deployment-to-production/index
   extensibility/index
   tutorials/index
