在Windows服务中处理任务
=====================================

要在Windows服务中开始使用Hangfire，您需要首先将Hangfire包安装到控制台应用程序。因此，使用您的软件包管理器控制台窗口进行安装：

.. code-block:: powershell

   PM> Install-Package Hangfire.Core

然后添加任务存储安装所需的软件包。例如，使用SQL Server：

.. code-block:: powershell

   PM> Install-Package Hangfire.SqlServer

.. admonition::  仅需 ``Hangfire.Core`` 软件包
   :class: note

   请不要为控制台应用安装 ``Hangfire`` 软件包，因为它只是一个快速开始的软件包，并且包含了可能不需要的依赖关系(例如 ``Microsoft.Owin.Host.SystemWeb``)。

安装软件包后, 只需新建一个 *Hangfire Server* 的实例，并像 :doc:`处理后台任务 <processing-background-jobs>` 一节中所述启动它。因此，打开该Windows服务的源代码文件，并将其修改如下。

.. code-block:: c#

   using System.ServiceProcess;
   using Hangfire;
   using Hangfire.SqlServer;

   namespace WindowsService1
   {
       public partial class Service1 : ServiceBase
       {
           private BackgroundJobServer _server;

           public Service1()
           {
               InitializeComponent();

               GlobalConfiguration.Configuration.UseSqlServerStorage("connection_string");
           }

           protected override void OnStart(string[] args)
           {
               _server = new BackgroundJobServer();
           }

           protected override void OnStop()
           {
               _server.Dispose();
           }
       }
   }

如果您是.NET项目中的Windows Services新手， 最好是先 google 有关的资料。但为了快速入门，您只需添加一个安装程序并配置它。要执行这些步骤，请返回服务类的设计视图，右键单击它并选择 ``Add Installer`` 菜单项。

.. image:: add-installer.png
   :alt: Adding installer to Windows Service project
   :align: center

然后构建您的项目，安装Windows服务并运行它。如果失败，请尝试查看您的 Windows Event 事件查看器,了解最新情况。

.. code-block:: powershell

   installutil <yourproject>.exe
