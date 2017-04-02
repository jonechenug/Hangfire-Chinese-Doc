使用 SQL Server 
=================

SQL Server是Hangfire的默认存储– 它是许多.NET开发人员所熟知的，并用于许多项目。 有趣的是，在Hangfire开发的早期阶段，Redis最先被用于存储任务的信息，NoSql的解决方案激发了SQL Server作为任务存储的灵感。还是说回SQL Server 。。。

SQL Server存储实现可通过 ``Hangfire.SqlServerNuGet`` 软件包获得。 请在NuGet软件包控制台窗口中输入以下命令安装：

.. code-block:: powershell

   Install-Package Hangfire.SqlServer

如果你已经安装 ``Hangfire`` NuGet软件包，不需要单独安装 ``Hangfire.SqlServer`` - 它已经被作为依赖添加到你的项目。

.. admonition:: 支持的数据库引擎
   :class: note

   **Microsoft SQL Server 2008R2** (任何版本，包括LocalDB)和更高版本以及 **Microsoft SQL Azure**.

.. admonition:: 不支持快照隔离!
   :class: warning

   **仅适用于Hangfire < 1.5.9**: 确保您的数据库不使用快照隔离级别，并且 ``READ_COMMITTED_SNAPSHOT`` 选项 (另一个名称为 *Is Read Committed Snapshot On*) **被禁用**。否则某些后台作业将不被处理。

配置
--------------

该包提供了GlobalConfiguration类的扩展方法。 使用任何你拥有的SQL Server的 `连接字符串 <https://www.connectionstrings.com/sqlconnection/>`_ 或者连接名称。

.. code-block:: c#

   GlobalConfiguration.Configuration
       // Use connection string name defined in `web.config` or `app.config`
       .UseSqlServerStorage("db_connection")
       // Use custom connection string
       .UseSqlServerStorage(@"Server=.\sqlexpress; Database=Hangfire; Integrated Security=SSPI;");

安装数据库
~~~~~~~~~~~~~~~~~~~

Hangfire有这么几个表和索引来存储后台任务和相关的其他信息：

.. image:: sql-schema.png

一些表用于核心功能，其他表用于满足可扩展性需求(使得可以在不更改基础架构的情况下编写扩展)。不使用像存储过程、触发器等高级特性, 以保持尽量简单并兼容SQL Azure。

 ``Install.sql`` 文件(位于NuGet包中的 ``tools`` 文件夹下) 将在 ``SqlServerStorage`` 的构造函数中 **自动执行** 到对应数据库。其中包括迁移脚本，因此可以无需您的干预，新版本的Hangfire对于数据库的变动将被无缝迁移。

如果要手动安装，或将其与现有迁移子系统进行集成,请修改SQL Server存储配置：

.. code-block:: c#

   var options = new SqlServerStorageOptions
   {
       PrepareSchemaIfNecessary = false
   };

   GlobalConfiguration.Configuration.UseSqlServerStorage("<name or connection string>", options);

配置轮询间隔
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

SQL Server存储有一个主要的的缺点- 它使用轮询技术来获取新任务。您可以调整轮询间隔，但是较低的间隔可能会损害您的SQL Server，而较高的间隔会产生太多延迟，因此请小心。

请注意， **不支持基于毫秒的间隔**，最低使用1秒间隔。

.. code-block:: c#

   var options = new SqlServerStorageOptions
   {
       QueuePollInterval = TimeSpan.FromSeconds(15) // Default value
   };

   GlobalConfiguration.Configuration.UseSqlServerStorage("<name or connection string>", options);

如果您想删除轮询技术，请考虑使用MSMQ扩展或Redis存储实现。

