使用 SQL Server 搭配 MSMQ
===========================

`Hangfire.SqlServer.MSMQ <https://www.nuget.org/packages/Hangfire.SqlServer.MSMQ/>`_ 这个扩展更改了Hangfire处理作业队列的方式。与SQL Server默认的 :doc:`实现 <using-sql-server>` 队列的常规方法不同, 它使用事务性MSMQ队列，更有效地处理任务：

======================== =============================== =================
特性                       原始SQL Server                  SQL Server + MSMQ
======================== =============================== =================
在进程终止后重试            重启后立即执行                   重启后立即执行

最差提取时间                轮询时间间隔（默认为15秒）        立即                                                    
======================== =============================== =================

因此，如果要使用SQL Server存储降低后台处理延迟时间，请考虑切换到使用MSMQ。

安装
-------------

MSMQ支持SQL Server作业存储实现，像其他Hangfire扩展一样，是一个NuGet包。您可以使用NuGet软件包管理器控制台窗口进行安装：

.. code-block:: powershell

   PM> Install-Package Hangfire.SqlServer.Msmq

配置
--------------

要使用MSMQ队列，您应该执行以下步骤：

1. **在每个主机上手动创建它们** 不要忘记授予适当的权限。请注意，默认情况下，队列存储限制为1048576 KB（大约2百万个入队作业），您可以通过MSMQ属性窗口增加队列存储空间。
2. 在当前所有的 ``SqlServerStorage`` 实例中注册MSMQ队列。

如果您 **只使用默认队列**，请在 ``UseSqlServerStorage`` 方法调用后调用 ``UseMsmqQueues`` 方法并将路径作为参数传递。

.. code-block:: c#

    GlobalConfiguration.Configuration
        .UseSqlServerStorage("<connection string or its name>")
        .UseMsmqQueues(@".\hangfire-{0}");

要使用多个队列，您应该明确地传递它们：

.. code-block:: c#

    GlobalConfiguration.Configuration
        .UseSqlServerStorage("<connection string or its name>")
        .UseMsmqQueues(@".\hangfire-{0}", "critical", "default");

限制
------------

* 在ASP.NET中，基于可靠性只支持事务性MSMQ队列。
* 您不能同时使用SQL Server作业队列和MSMQ作业队列实现（见下文）。此限制仅适用于Hangfire Server。您仍然可以将任务排队到任何类型的队列，并在Hangfire仪表盘中查看。

切换到MSMQ队列
--------------------------

请使用 ``seMsmqQueues`` 方法新增MSMQ队列。否则，您的系统在SQL Server存储中可能有未处理的作业。由于一个Hangfire Server实例无法处理来自不同类型的队列中的任务，因此您应该部署 :doc:`多个 Hangfire Server实例 <../background-processing/running-multiple-server-instances>` ，一个仅监听MSMQ队列，另一个仅监视SQL Server队列。当后者完成工作（您可以在仪表板中看到这一点 - 您的SQL Server队列将被删除），就可以安全地删除它。

如果您仅使用默认队列，请执行以下操作：

.. code-block:: c#

    /* This server will process only SQL Server table queues, i.e. old jobs */
    var oldStorage = new SqlServerStorage("<connection string or its name>");
    var oldOptions = new BackgroundJobServerOptions
    {
        ServerName = "OldQueueServer" // Pass this to differentiate this server from the next one
    };

    app.UseHangfireServer(oldOptions, oldStorage);

    /* This server will process only MSMQ queues, i.e. new jobs */
    GlobalConfiguration.Configuration
        .UseSqlServerStorage("<connection string or its name>")
        .UseMsmqQueues(@".\hangfire-{0}");

    app.UseHangfireServer();

如果您使用多个队列，请执行以下操作：

.. code-block:: c#

    /* This server will process only SQL Server table queues, i.e. old jobs */
    var oldStorage = new SqlServerStorage("<connection string>");
    var oldOptions = new BackgroundJobServerOptions
    {
        Queues = new [] { "critical", "default" }, // Include this line only if you have multiple queues
        ServerName = "OldQueueServer" // Pass this to differentiate this server from the next one
    };

    app.UseHangfireServer(oldOptions, oldStorage);

    /* This server will process only MSMQ queues, i.e. new jobs */
    GlobalConfiguration.Configuration
        .UseSqlServerStorage("<connection string or its name>")
        .UseMsmqQueues(@".\hangfire-{0}", "critical", "default");

    app.UseHangfireServer();
