使用性能计数器
===========================

.. admonition:: 仅限Pro
   :class: note

   此功能是 `Hangfire Pro <http://hangfire.io/pro/>`_ 软件包的一部分。

性能计数器是在Windows平台上 `测量 <http://blogs.msdn.com/b/securitytools/archive/2009/11/04/how-to-use-perfmon-in-windows-7.aspx>`_ 不同应用程序度量的标准方法。该软件包使Hangfire能够发布性能计数器，以便您可以使用不同的工具（包括 `Performance Monitor <http://technet.microsoft.com/en-us/library/cc749249.aspx>`_ 、 `Nagios <http://www.nagios.org/>`_ 、 `New Relic <http://newrelic.com/>`_ 等）。

.. image:: perfmon.png

安装
-------------

在配置Hangfire并开始发布性能计数器之前，您需要在每台运行 ``hangfire-perf.exe`` 程序的机器上传入 ``ipc`` 参数 (每次安装或更新操作时):

.. code-block:: powershell
 
   hangfire-perf ipc

要卸载性能计数器，请使用 ``upc`` 参数:

.. code-block:: powershell

   hangfire-perf upc

配置
--------------

性能计数器通过 ``Hangfire.Pro.PerformanceCounters`` 软件包安装。将其添加到您的项目之后，您只需要通过调用以下方法来初始化它们：

.. code-block:: csharp

   using Hangfire.PerformanceCounters;

   PerformanceCounters.Initialize("unique-app-id");

在OWIN启动类中的初始化逻辑容易得多：

.. code-block:: csharp

   using Hangfire.PerformanceCounters;

   public void Configure(IAppBuilder app)
   {
       app.UseHangfirePerformanceCounters();
   }

性能计数器
---------------------

以下是实现的性能计数器列表：

* Creation Process Executions
* Creation Process Executions/Sec
* Performance Process Executions
* Performance Process Executions/Sec
* Transitions to Succeeded State
* Transitions to Succeeded State/Sec
* Transitions to Failed State/Sec

想要更多？只需打开一个 `GitHub Issue <https://github.com/HangfireIO/Hangfire/issues/new>`_ 并描述您想要查看的指标。