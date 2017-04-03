传递依赖
=======================

在应用中，您希望使用不同的类来处理不同的任务以保持代码的简洁。我们把这些类称为 *依赖*。如何将这些依赖关系传递给将在后台任务调用的方法呢？

当您在后台任务中调用静态方法时，仅限于应用程序的静态上下文，这需要您使用以下获取依赖关系的模式：

* 通过 ``new`` 手动实例化依赖
* `服务定位器模式 <http://en.wikipedia.org/wiki/Service_locator_pattern>`_
* `抽象工厂模式 <http://en.wikipedia.org/wiki/Abstract_factory_pattern>`_ 或 `建设者模式 <http://en.wikipedia.org/wiki/Builder_pattern>`_
* `单例模式 <http://en.wikipedia.org/wiki/Singleton_pattern>`_

然而，所有这些模式使您的应用程序的单元可测试性方面变得非常复杂。为了解决这个问题，Hangfire允许你在后台任务调用实例方法。想象你有以下的类使用 ``DbContext`` 的某种方式去连接数据库，并且使用 ``EmailService`` 发送邮件。

.. code-block:: c#

    public class EmailSender
    {
        public void Send(int userId, string message) 
        {
            var dbContext = new DbContext();
            var emailService = new EmailService();

            // Some processing logic
        }
    }

为了在后台任务中调用 ``Send`` 方法,使用以下的方法重写 ``Enqueue`` 方法 ( ``BackgroundJob`` 类的其他方法也提供此类重载)：

.. code-block:: c#

   BackgroundJob.Enqueue<EmailSender>(x => x.Send(13, "Hello!"));

当一个worker 需要调用一个实例方法时，它首先使用当前的 ``JobActivator`` 来实例化给定的类。默认情况下，使用 ``Activator.CreateInstance`` 方法可以为你的类创建一个 **默认构造函数** 的实例,如下：

.. code-block:: c#

   public class EmailSender
   {
       private IDbContext _dbContext;
       private IEmailService _emailService;

       public EmailSender()
       {
           _dbContext = new DbContext();
           _emailService = new EmailService();
       } 

       // ...
   }

如果您希望类可以进行单元测试，请考虑重载构造函数，因为 **默认的 Activator 无法创建一个没有默认构造函数的类的实例** :

.. code-block:: c#

    public class EmailSender
    {
        // ...

        public EmailSender()
            : this(new DbContext(), new EmailService())
        {
        }

        internal EmailSender(IDbContext dbContext, IEmailService emailService)
        {
            _dbContext = dbContext;
            _emailService = emailService;
        }
    }

如果您使用IoC容器，例如Autofac，Ninject，SimpleInjector等，可以删除默认构造函数。要了解更多，请继续下一节。
