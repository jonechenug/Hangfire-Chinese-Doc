使用 Redis
============

.. admonition:: 仅限 Pro

  从Hangfire 1.2开始，此功能是 `Hangfire Pro <http://hangfire.io/pro/>`_ 软件包的一部分。

使用Redis存储的Hangfire比使用SQL Server存储执行任务快得多。在我的开发机器上，我观察到执行同样的空白任务（不做任何事情的方法），吞吐量改善4倍多。 ``Hangfire.Pro.Redis`` 利用 ``BRPOPLPUSH`` 命令获取作业，因此任务处理延迟保持最小。

.. image:: storage-compare.png
   :align: center

请参阅 `下载页面 <http://redis.io/download>`_ 获取最新版本的Redis。 如果您不熟悉Redis，请参阅其 `文档 <http://redis.io/documentation>`_。 Windows的二进制文件可以通过NuGet (`32-bit <https://www.nuget.org/packages/Redis-32/>`_， `64-bit <https://www.nuget.org/packages/Redis-64/>`_) 和 Chocolatey galleries (仅有 `64-bit <http://chocolatey.org/packages/redis-64>`_ )获取。

限制
------------

尽管StackExchange.Redis库确实支持以下一些功能，但我们不能立即使用它们。例如，为了通过主/从复制来支持高可用性，我们必须先实现 `Redlock <http://redis.io/topics/distlock>`_ 算法，以确保在分布式锁的情况下仍正常工作。为了支持群集以及对应的Redlock算法，我们必须确保订阅一直正常运行。

**因此，不支持Redis多节点、Redis集群和Redis主从切换。**

配置Redis数据库
--------------------

请阅读 `Redis的官方文档 <http://redis.io/documentation>`_ ，了解如何进行配置，特别是 `Redis Persistence <http://redis.io/topics/persistence>`_ 和 `Redis Administration <http://redis.io/topics/admin>`_ 部分的基础知识。保证后台任务平稳运行应配置以下选项：

.. admonition:: 确保配置了以下选项
   :class: warning

   这些值是Redis的默认值，但不同环境可能有不同的默认值，例如 **Azure Redis Cache** 和 **AWS ElastiCache** 默认情况下 **有不兼容的设置** 。

.. code-block:: shell

   # 非零值导致长时间运行的后台任务
   # 由于连接被关闭而被多次处理
   # 注意: 此设置仅适用于 Hangfire.Pro.Redis 1.x!
   timeout 0

   # Hangfire 既不希望Redis的永久键(non-expired keys)被删除,
   # 也不希望Redis的限时键(expiring keys)被提前移除
   maxmemory-policy noeviction

Hangfire.Pro.Redis 2.x
-----------------------



需要Redis≥2.6

安装
~~~~~~~~~~~~~

确保您已配置了私有的 Hangfire Pro NuGet软件包（ `地址 <http://hangfire.io/pro/downloads.html#configuring-feed>`_ ），并且使用自己喜欢的的NuGet客户端安装 ``Hangfire.Pro.Redis`` 软件包：

.. code-block:: powershell

   PM> Install-Package Hangfire.Pro.Redis

如果您的项目针对.NET Core，只需在 ``project.json`` 文件中添加依赖关系：

.. code-block:: json

   "dependencies": {
       "Hangfire.Pro.Redis": "2.0.2"
   }

配置
~~~~~~~~~~~~~~

安装软件包后，可以使用一些 ``UseRedisStorage`` 的扩展方法重载来实现 ``IGlobalConfiguration`` 接口。 允许您使用 *配置字符串* 和Hangfire特有的 *选项* 配置Redis任务存储。

连接字符串
^^^^^^^^^^^^^^^^^

最基础的一项，默认连接到 *localhost* 的Redis服务器的默认端口，使用默认的配置:

.. code-block:: csharp

   GlobalConfiguration.Configuration.UseRedisStorage();

对于ASP.NET Core项目，在 ``AddHangfire`` 方法的委托中调用 ``UseRedisStorage`` 方法:

.. code-block:: csharp

   services.AddHangfire(configuration => configuration.UseRedisStorage());

您可以使用 'StackExchange.Redis' 配置连接字符串的方法自定义连接，请阅读 `StackExchange.Redis的文档 <https://github.com/StackExchange/StackExchange.Redis/blob/master/Docs/Configuration.md>`_ 了解详情。以下选项的值在Hangfire中具有自己的默认值，但可以在 *连接字符串* 中覆盖：

=============== =======
选项             默认
=============== =======
``syncTimeout`` ``30000``
``allowAdmin``  ``true``
=============== =======

.. code-block:: csharp

   GlobalConfiguration.Configuration
       .UseRedisStorage("contoso5.redis.cache.windows.net,abortConnect=false,ssl=true,password=...");

在.NET Core中，您需要使用IP地址，因为在.NET Core中的StackExchange.Redis中不能使用DNS查找。

.. code-block:: csharp

   GlobalConfiguration.Configuration
       .UseRedisStorage("127.0.0.1");

特殊配置选项
^^^^^^^^^^^^^^^

您还可以通过 ``RedisStorageOptions`` 类的实例实现Hangfire的特殊选项：

.. code-block:: csharp

   var options = new RedisStorageOptions
   {
       Prefix = "hangfire:app1:",
       InvisibilityTimeout = TimeSpan.FromHours(3)
   };

   GlobalConfiguration.Configuration.UseRedisStorage("localhost", options);

以下选项可用于配置：

============================ ============================ ===========
选项                          配置                         描述
============================ ============================ ===========
Database                     ``null``                     Hangfire使用的Redis服务器，空的情况下使用默认的连接字符串
InvisibilityTimeout          ``TimeSpan.FromMinutes(30)`` 任务转移间隔, 在这段间隔内，后台任务任为同一个worker处理；超时后将转移到另一个worker处理
Prefix                       ``hangfire:``                在Redis存储中Hangfire使用的Key前缀
MaxSucceededListLength       ``10000``                    成功列表中的最大可见后台任务，以防止其无限期增长。
MaxDeletedListLength         ``1000``                     删除列表中的最大可见后台作业，以防止其无限期增长。
SubscriptionIntegrityTimeout ``TimeSpan.FromHours(1)``    执行订阅的时间间隔，该值应足够高（按小时）以减少数据库的压力。反之为保证完整性，每几周执行订阅时，这期间可能有意外发生。
============================ ============================ ===========

Hangfire.Pro.Redis 1.x
-----------------------

这是Hangfire的Redis任务存储的旧版本。它基于 `ServiceStack.Redis 3.71 <https://github.com/ServiceStack/ServiceStack.Redis/tree/v3>`_，并且不支持SSL、不支持.NET Core。**此版本已弃用** ， 不会添加任何新功能，请切换到新版本以获取新功能。

配置
~~~~~~~~~~~~~~

Hangfire.Pro.Redis包包含一些 ``GlobalConfiguration`` 类的扩展方法：

.. code-block:: c#

   GlobalConfiguration.Configuration
       // Use localhost:6379
       .UseRedisStorage();
       // Using hostname only and default port 6379
       .UseRedisStorage("localhost");
       // or specify a port
       .UseRedisStorage("localhost:6379");
       // or add a db number
       .UseRedisStorage("localhost:6379", 0);
       // or use a password
       .UseRedisStorage("password@localhost:6379", 0);

   // or with options
   var options = new RedisStorageOptions();
   GlobalConfiguration.Configuration
       .UseRedisStorage("localhost", 0, options);

配置连接池大小
~~~~~~~~~~~~~~~~~~~~~

Hangfire利用连接池快速连接并缩短使用时间。您可以配置池大小以满足您的环境需求：

.. code-block:: c#

   var options = new RedisStorageOptions
   {
       ConnectionPoolSize = 50 // default value
   };

   GlobalConfiguration.Configuration.UseRedisStorage("localhost", 0, options);

配置Redis键(Key)前缀
~~~~~~~~~~~~~~~~~~~

如果您在多个环境中使用共享的Redis服务器，则可以为每个环境指定唯一的前缀：

.. code-block:: c#

   var options = new RedisStorageOptions
   {
       Prefix = "hangfire:"; // default value
   };

   GlobalConfiguration.Configuration.UseRedisStorage("localhost", 0, options);
