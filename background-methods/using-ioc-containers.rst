使用ioc容器
=====================

正如我在 :doc:`上一节 <passing-dependencies>` 中所述，在调用实例方法之前，Hangfire 使用 ``JobActivator`` 来实例化目标类型。您可以通过重写类型的实例化来执行更复杂的逻辑。例如，您可以在项目中使用IoC容器：

.. code-block:: c#

   public class ContainerJobActivator : JobActivator
   {
       private IContainer _container;

       public ContainerJobActivator(IContainer container)
       {
           _container = container;
       }

       public override object ActivateJob(Type type)
       {
           return _container.Resolve(type);
       }
   }

然后在启动Hangfire服务器之前，将其注册:

.. code-block:: c#

   // Somewhere in bootstrap logic, for example in the Global.asax.cs file
   var container = new Container();
   GlobalConfiguration.Configuration.UseActivator(new ContainerJobActivator(container));
   ...
   app.UseHangfireServer();

为了简化初始安装，NuGet上已经有一些集成软件包：

* `Hangfire.Autofac <https://www.nuget.org/packages/Hangfire.Autofac/>`_
* `Hangfire.Ninject <https://www.nuget.org/packages/Hangfire.Ninject/>`_
* `Hangfire.SimpleInjector <https://www.nuget.org/packages/Hangfire.SimpleInjector/>`_
* `Hangfire.Windsor <https://www.nuget.org/packages/Hangfire.Windsor/>`_

其中某些软件包还为 ``GlobalConfiguration`` 提供了一个扩展:

.. code-block:: c#

   GlobalConfiguration.Configuration.UseNinjectActivator(kernel);

.. admonition:: ``HttpContext`` 不可用
   :class: warning
   
   在目标类型的实例化过程中，Request information是不可用的。如果您在一个请求作用域(Autofac的 ``InstancePerHttpRequest`` ， Ninject的 ``InRequestScope`` ) 中注册了依赖项，则在任务激活过程中将抛出异常。

所以， **整个依赖项必须是可用的** 。要么注册其他服务而不使用请求作用域， 或者当您的ioc容器不支持多个作用域时使用不同的实例。
