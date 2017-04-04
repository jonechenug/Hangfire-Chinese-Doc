运行多个服务实例
==================================

.. admonition:: 自1.5后就过时了
   :class: note
   
   在Hangfire 1.5之后，您不需要额外的配置来支持多个服务实例处理同一个后台任务，可以跳过本文了。现在使用GUID生成服务器标识符，因此所有实例名称都是唯一的。

可以同时在一个程序、机器或多台机器上运行多个服务器实例。每个服务实例使用分布式锁来执行协调逻辑。

在上述情况中，每个Hangfire服务器都有一个唯一的由两部分组成的供默认值标识符。最后一部分是一个程序标识，用于区别同一台机器上的多个服务实例。前一部分是 *服务名称*，默认为机器名，保证不同机器的唯一性。例如: ``server1:9853``、 ``server1:4531`` 、 ``server2:6742``。

由于默认值只是在程序级别提供唯一性，因此如果要在同一程序内运行不同的服务实例，则应手动处理它们：

.. code-block:: c#

    var options = new BackgroundJobServerOptions
    {
        ServerName = String.Format(
            "{0}.{1}",
            Environment.MachineName,
            Guid.NewGuid().ToString())
    };

    var server = new BackgroundJobServer(options);

    // or
    
    app.UseHangfireServer(options);
