在Web应用程序中处理任务
=====================================

能够在Web应用程序中直接处理后台任务是Hangfire的主要目标。处理后台任务不需要Windows服务或控制台应用程序等外部应用程序，但您根据需要改变架构。因此，您可以实现复杂的架构。

由于Hangfire没有对 ``System.Web`` 的依赖，因此可以与.NET的任何Web框架一起使用：

* ASP.NET WebForms
* ASP.NET MVC
* ASP.NET WebApi
* ASP.NET vNext (通过 ``app.UseOwin`` 方法)
* 其他基于OWIN的网络框架 (`Nancy <http://nancyfx.org/>`_, `FubuMVC <http://mvc.fubu-project.org/>`_, `Simple.Web <https://github.com/markrendle/Simple.Web>`_)
* 其他非OWIN的Web框架 (`ServiceStack <https://servicestack.net/>`_)

使用 ``BackgroundJobServer`` 
------------------------------------

 在一个web框架中，基础 (但不简单 -- 参阅下节) 的使用方法是调用与主机无关的 ``BackgroundJobServer`` 类中的 ``Start`` 和 ``Dispose`` 方法（参阅 :doc:`前一章 <processing-background-jobs>`）。

.. admonition:: 尽可能释放服务器实例
   :class: note

   在某些Web应用程序框架中，如果何时调用 ``Dispose`` 方法不是很清楚的情况下，您可以 :doc:`像这样 <processing-background-jobs>` 调用(但可能非 *正确关闭* )。

例如，在ASP.NET应用程序中，调用 start/dispose 方法的最佳方式是在 ``global.asax.cs`` 文件中:

.. code-block:: c#

   using System;
   using System.Web;
   using Hangfire;

   namespace WebApplication1
   {
       public class Global : HttpApplication
       {
           private BackgroundJobServer _backgroundJobServer;

           protected void Application_Start(object sender, EventArgs e)
           {
               GlobalConfiguration.Configuration
                   .UseSqlServerStorage("DbConnection");
           
               _backgroundJobServer = new BackgroundJobServer();
           }

           protected void Application_End(object sender, EventArgs e)
           {
               _backgroundJobServer.Dispose();
           }
       }
   }

使用OWIN扩展方法
-----------------------------

Hangfire还提供了一个可以在OWIN中处理请求的仪表盘。如果您有简单的Hangfire初始化逻辑，考虑在 ``IAppBuilder`` 接口中使用Hangfire的OWIN扩展方法:

.. admonition:: 为 ASP.NET + IIS 安装 ``Microsoft.Owin.Host.SystemWeb``
   :class: warning

   如果您想要在IIS托管的ASP.NET应用程序中使用OWIN扩展方法，请确保已安装 ``Microsoft.Owin.Host.SystemWeb`` 软件包。 否则一些功能，如 `正常关闭 <processing-background-jobs>`_ 的功能可能无法正常使用。
   
   如果你已经安装 ``Hangfire`` 软件包, 则此依赖项已被安装。

.. code-block:: c#

    public class Startup
    {
        public void Configuration(IAppBuilder app)
        {
            app.UseHangfireServer();
        }
    }

将自动创建一个新的  ``BackgroundJobServer`` 类的实例，调用 ``Start`` 方法 并在应用程序关闭时调用 ``Dispose`` 方法。 后者是通过存储在 ``host.OnAppDisposing`` 的环境变量中的 ``CancellationToken`` 实现的。
