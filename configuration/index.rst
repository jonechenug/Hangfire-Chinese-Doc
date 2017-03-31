配置
==============

从1.4版本开始, ``GlobalConfiguration`` 类是配置Hangfire的首选方式.这里有一些重要入口方法,包括来自第三方存储实现或其他扩展。 用法很简单,在应用程序初始化类中包含 ``Hangfire`` 命名空间， 在 ``GlobalConfiguration.Configuration`` 属性中使用这些扩展方法。

例如, 在 ASP.NET 应用程序中,您可以将初始化逻辑放在 ``Global.asax.cs`` 文件中:

.. code-block:: c#

    using Hangfire;

    public class MvcApplication : System.Web.HttpApplication
    {
        protected void Application_Start()
        {
            // Storage is the only thing required for basic configuration.
            // Just discover what configuration options do you have.
            GlobalConfiguration.Configuration
                .UseSqlServerStorage("<name or connection string>");
                //.UseActivator(...)
                //.UseLogProvider(...)
        }
    }

对于基于OWIN的应用程序（ASP.NET MVC，Nancy，ServiceStack，FubuMVC等）， 在 OWIN 启动类中写入配置。

.. code-block:: c#

    using Hangfire;

    [assembly: OwinStartup(typeof(Startup))]
    public class Startup
    {
        public void Configuration(IAppBuilder app)
        {
            GlobalConfiguration.Configuration.UseSqlServerStorage("<name or connection string>");
        }
    }

对于其他程序, 在调用其他Hangfire方法 **之前** 写入配置。

.. toctree::
   :maxdepth: 1

   using-dashboard
   using-sql-server
   using-sql-server-with-msmq
   using-redis
   configuring-logging