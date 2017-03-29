安装
=============

在 `NuGet Gallery  <https://www.nuget.org/packages?q=hangfire>`_.可以找到关于Hangfire的一系列软件包。以下是您应该了解的基本软件包列表：

* `Hangfire <https://www.nuget.org/packages/Hangfire/>`_ – 引导程序包，**只** 针对使用SQL Server作为作业存储的ASP.NET应用程序安装。 它引用了 `Hangfire.Core <https://www.nuget.org/packages/Hangfire.Core/>`_, `Hangfire.SqlServer <https://www.nuget.org/packages/Hangfire.SqlServer/>`_ 和 `Microsoft.Owin.Host.SystemWeb <https://www.nuget.org/packages/Microsoft.Owin.Host.SystemWeb/>`_ .
* `Hangfire.Core <https://www.nuget.org/packages/Hangfire.Core/>`_ – 包含Hangfire所有核心组件的基本软件包。它可以用于任何项目类型，包括ASP.NET应用程序，Windows服务，控制台，OWIN相关的Web应用程序， Azure Worker Role 等。

.. admonition:: 为ASP.NET + IIS 安装 ``Microsoft.Owin.Host.SystemWeb`` 软件包
   :class: warning

   如果您在IIS中托管的Web应用程序中使用自定义安装，请勿忘记安装 `Microsoft.Owin.Host.SystemWeb <https://www.nuget.org/packages/Microsoft.Owin.Host.SystemWeb/>`_ 软件包。否则一些功能，如可能无法正常停止。

使用 Package Manager Console
------------------------------

.. code-block:: c#

   PM> Install-Package Hangfire

使用 NuGet Package Manager
----------------------------

在Visual Studio中右击你的项目并选择 ``Manage NuGet Packages`` 菜单。 搜索 ``Hangfire`` 并安装所需的软件包:

.. image:: package-manager.png
   :alt: NuGet Package Manager window