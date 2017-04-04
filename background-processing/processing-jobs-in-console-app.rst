在控制台应用程序中处理任务
=========================================

要在控制台应用程序中开始使用Hangfire，您需要首先将Hangfire包安装到控制台应用程序。因此，使用您的软件包管理器控制台窗口进行安装：

.. code-block:: powershell

   PM> Install-Package Hangfire.Core

然后添加任务存储安装所需的软件包。例如，使用SQL Server：

.. code-block:: powershell

   PM> Install-Package Hangfire.SqlServer

.. admonition:: 仅需 ``Hangfire.Core`` 软件包
   :class: note

   Please don't install the ``Hangfire`` package for console applications as it is a quick-start package only and contain dependencies you may not need (for example, ``Microsoft.Owin.Host.SystemWeb``).

安装软件包后, 只需新建一个 *Hangfire Server* 的实例并像 :doc:`前面章节 <processing-background-jobs>` 一样启动它。不过，还可以有一些细节：

* 由于 ``Start`` 方法是 **非堵塞** 的，通过调用 ``Console.ReadKey``  方法防止被在应用中被关闭。
* 对 ``Stop`` 方法的调用是隐式的 -- 它是通过 ``using`` 语句完成的。

.. code-block:: c#

   using System;
   using Hangfire;
   using Hangfire.SqlServer;

   namespace ConsoleApplication2
   {
       class Program
       {
           static void Main()
           {
               GlobalConfiguration.Configuration.UseSqlServerStorage("connection_string");

               using (var server = new BackgroundJobServer())
               {
                   Console.WriteLine("Hangfire Server started. Press any key to exit...");
                   Console.ReadKey();
               }
           }
       }
   }
