编写单元测试
===================

我不会告诉你有关后台任务的单元测试的任何内容，因为Hangfire没有添加任何特定方法 (除了 ``IJobCancellationToken`` 接口参数)去改变任务。使用您最喜爱的工具，并照常写入单元测试。本节介绍如何测试创建的后台任务。

所有的代码示例都使用静态 ``BackgroundJob`` 类来告诉你如何做这个或那些东西，只是出于简单演示的目的。但是当你想测试调用的静态方法时，会变得很痛苦。

不用担心 - ``BackgroundJob`` 类只是 ``IBackgroundJobClient`` 接口及其默认实现 ``BackgroundJobClient`` 类的一个入口。如果要编写单元测试，请使用它们。例如，假设在以下控制器入队一个后台任务：

.. code-block:: c#

    public class HomeController : Controller
    {
        private readonly IBackgroundJobClient _jobClient;

        // For ASP.NET MVC
        public HomeController()
            : this(new BackgroundJobClient())
        {
        }

        // For unit tests
        public HomeController(IBackgroundJobClient jobClient)
        {
            _jobClient = jobClient;
        }

        public ActionResult Create(Comment comment)
        {
            ...
            _jobClient.Enqueue(() => CheckForSpam(comment.Id));
            ...
        }
    }

很简单，对吧。现在你可以使用任何 mocking 框架, 如提供mocks和检查调用的 `Moq <https://github.com/Moq/moq4>`_ 。 ``IBackgroundJobClient`` 接口仅提供 ``Create`` 方法来创建后台任务并实例化对应的类。通过 ``Job`` 类的实例了解后台任务的信息，通过 ``IState`` 接口了解后台任务的状态。

.. code-block:: c#

    [TestMethod]
    public void CheckForSpamJob_ShouldBeEnqueued()
    {
        // Arrange
        var client = new Mock<IBackgroundJobClient>();
        var controller = new HomeController(client.Object);
        var comment = CreateComment();

        // Act
        controller.Create(comment);

        // Assert
        client.Verify(x => x.Create(
            It.Is<Job>(job => job.Method.Name == "CheckForSpam" && job.Args[0] == comment.Id),
            It.IsAny<EnqueuedState>());
    }
    
.. note::

   ``job.Method`` 属性仅适用于后台任务的方法信息。如果您还想检查类型名称，请使用 ``job.Type`` 属性。
