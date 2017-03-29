使用仪表盘
================

Hangfire 仪表盘可以找到所有后台任务信息。它被写成一个OWIN中间件(如果你不熟悉OWIN也不用担心), 所以你可以在 ASP.NET, ASP.NET MVC, Nancy, ServiceStack 以及 使用 `OWIN Self-Host <http://www.asp.net/web-api/overview/hosting-aspnet-web-api/use-owin-to-self-host-web-api>`_ 特性的控制台应用程序或Windows服务中使用仪表盘。

.. contents::
   :local:

添加仪表盘
-----------------

.. admonition:: ASP.NET + IIS 需要额外的软件包

  在进行下一步之前，请确保你已经安装 `Microsoft.Owin.Host.SystemWeb <https://www.nuget.org/packages/Microsoft.Owin.Host.SystemWeb/>`_ 软件包，否则您将在仪表盘中遇到各种不同的奇怪问题。

`OWIN Startup class <http://www.asp.net/aspnet/overview/owin-and-katana/owin-startup-class-detection>`_ 将 web 应用程序启动逻辑统一在一个单一的位置。 在 Visual Studio 2013 您可以通过右键单击项目并选择 *Add / OWIN Startup Class* 菜单来添加它。

.. image:: add-owin-startup.png


如果您有 Visual Studio 2012 或更早版本，只需在应用程序的根文件夹中创建一个常规类，将其命名 ``Startup`` 并输入以下内容：

.. code-block:: c#

    using Hangfire;
    using Microsoft.Owin;
    using Owin;

    [assembly: OwinStartup(typeof(MyWebApplication.Startup))]

    namespace MyWebApplication
    {
        public class Startup
        {
            public void Configuration(IAppBuilder app)
            {
                // Map Dashboard to the `http://<your-app>/hangfire` URL.
                app.UseHangfireDashboard();
            }
        }
    }

执行这些步骤后，打开浏览器并点击 *http://<your-app>/hangfire* 进入仪表盘。

.. admonition:: 需要配置授权
   :class: warning

   默认情况下，Hangfire **只允许本地访问** 仪表盘。在生产环境中需要配置相关的使用权限，请参阅 `配置授权`_ 部分。

配置授权
--------------------------

Hangfire 仪表盘公开了后台作业的敏感信息，包括方法名称和序列化参数，还可以通过执行不同的操作（重试，删除，触发器等）来管理这些信息。因此，限制对仪表盘的访问非常重要。

默认情况下, 只 **允许本地访问**, 但是您可以通过继承 ``IAuthorizationFilter`` 接口实现特定的授权规则，  ``Authorize`` 方法用于允许或禁止请求。第一步是提供自己的实现。

.. admonition:: 不想重复造轮子？
   :class: note

   如NuGet软件包 `Hangfire.Dashboard.Authorization <https://github.com/HangfireIO/Hangfire.Dashboard.Authorization>`_ 实现用户、角色和权限，以及基于访问身份验证（简单的登录密码验证）的授权筛选器，

.. code-block:: c#

    public class MyRestrictiveAuthorizationFilter : IAuthorizationFilter
    {
         public bool Authorize(IDictionary<string, object> owinEnvironment)
         {
             // In case you need an OWIN context, use the next line,
             // `OwinContext` class is the part of the `Microsoft.Owin` package.
             var context = new OwinContext(owinEnvironment);

             // Allow all authenticated users to see the Dashboard (potentially dangerous).
             return context.Authentication.User.Identity.IsAuthenticated;
         }
    }

第二步是将其传递给 ``UseHangfireDashboard`` 方法。您可以传递多个过滤器，只有当 *所有过滤器* 都返回时，才会授予 ``允许`` 访问权限。

.. code-block:: c#

    app.UseHangfireDashboard("/hangfire", new DashboardOptions
    {
        AuthorizationFilters = new[] { new MyRestrictiveAuthorizationFilter() }
    });

.. admonition:: 方法调用顺序很重要
   :class: warning

   在OWIN启动类中的 **其他身份验证方法之后** 调用 ``UseHangfireDashboard`` 方法。否则认证可能无效。

   .. code-block:: c#

        public void Configuration(IAppBuilder app)
        {            
            app.UseCookieAuthentication(...); // Authentication - first
            app.UseHangfireDashboard();       // Hangfire - last
        }

更改URL映射
-------------------

默认情况下， ``UseHangfireDashboard`` 方法将仪表盘映射到 ``/hangfire`` 路径。如果您希望通过某种原因更改此设置，只需传递URL路径即可。

.. code-block:: c#

   // Map the Dashboard to the root URL
   app.UseHangfireDashboard("");

   // Map to the `/jobs` URL
   app.UseHangfireDashboard("/jobs");

更改 *返回站点* 链接
---------------------------

默认情况下， *返回站点* 链接 (仪表盘右上角) 将指向应用程序的根路径。请使用 ``DashboardOptions`` 改变它。

.. code-block:: c#

   // Change `Back to site` link URL
   var options = new DashboardOptions { AppPath = "http://your-app.net" };
   // Make `Back to site` link working for subfolder applications
   var options = new DashboardOptions { AppPath = VirtualPathUtility.ToAbsolute("~") };

   app.UseHangfireDashboard("/hangfire", options);

多个仪表盘
--------------------

您还可以映射多个显示不同存储仓储的仪表盘。

.. code-block:: c#

   var storage1 = new SqlServerStorage("Connection1");
   var storage2 = new SqlServerStorage("Connection2");

   app.UseHangfireDashboard("/hangfire1", new DashboardOptions(), storage1);
   app.UseHangfireDashboard("/hangfire2", new DashboardOptions(), storage2);



