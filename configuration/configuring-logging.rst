配置日志
====================

从Hangfire 1.3.0开始, **不需要做任何事情**, 如果你的应用程序已经使用了以下任何一个库，通过反射，Hangfire 本身不依赖于日志类。将通过检查是否有下列的顺序对应的日志库后 **自动选择** 。

1. `Serilog <http://serilog.net/>`_ 
2. `NLog <http://nlog-project.org/>`_
3. `Log4Net <https://logging.apache.org/log4net/>`_
4. `EntLib Logging <http://msdn.microsoft.com/en-us/library/ff647183.aspx>`_
5. `Loupe <http://www.gibraltarsoftware.com/Loupe>`_
6. `Elmah <https://code.google.com/p/elmah/>`_

如果要记录Hangfire事件却没有安装日志库，任选上述一个库并参考其文档。

控制台日志
---------------

对于控制台应用程序和沙盒应用，可以通过执行以下操作来使用 ``ColouredConsoleLogProvider`` 类： 

.. code-block:: csharp

   LogProvider.SetCurrentLogProvider(new ColouredConsoleLogProvider());

添加自定义日志
-----------------------

实现自定义日志非常简单，如果您的应用程序使用了上面没有列出的日志记录库，则只需要实现以下接口：

.. code-block:: csharp

    public interface ILog
    {
        /// <summary>
        /// Log a message the specified log level.
        /// </summary>
        /// <param name="logLevel">The log level.</param>
        /// <param name="messageFunc">The message function.</param>
        /// <param name="exception">An optional exception.</param>
        /// <returns>true if the message was logged. Otherwise false.</returns>
        /// <remarks>
        /// Note to implementers: the message func should not be called if the loglevel is not enabled
        /// so as not to incur performance penalties.
        /// 
        /// To check IsEnabled call Log with only LogLevel and check the return value, no event will be written
        /// </remarks>
        bool Log(LogLevel logLevel, Func<string> messageFunc, Exception exception = null);
    }

    public interface ILogProvider
    {
        ILog GetLogger(string name);
    }

实现上述接口后，调用以下方法：

.. code-block:: csharp

    LogProvider.SetCurrentLogProvider(new CustomLogProvider());

Log level description
----------------------

* **Trace** – 用于Hangfire自身调试。
* **Debug** – 了解后台任务为何不工作。
* **Info**  – 看到正常工作的信息：Hangfire启动或停止，Hangfire组件如期执行任务。这是建议的日志级别。
* **Warn**  – 提前了解潜在的问题：*执行失败但将重试任务*， *线程异常中止*。
* **Error** – 了解后台任务中断或应该告知你的问题: *执行失败但需要手工重试或删除*, *无法连接到任务存储库但将会自动重新连接*。
* **Fatal** – 了解需要人工干预的后台任务部分或完全不工作的原因: *任务存储连接失败，重试后还是失败*, *多种内部错误，如 OutOfMemoryException 等*。
