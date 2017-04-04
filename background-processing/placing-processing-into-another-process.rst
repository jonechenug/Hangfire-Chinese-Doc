在另一个进程中处理
========================================

您可以将主应用中的处理任务转移到不同的的程序中。 例如，可以将您的web应用影响到性能的任务转移到别的控制台应用程序或Windows服务中。让我们探讨这么做的原因吧。

适用场景
---------------

* 您的后台任务消耗 **太多的CPU或其他资源**,这会降低主应用的性能。所以你希望使用单独的机器来处理后台任务。
* 由于主应用定期关机，导致有长期运行的 **不断暂停** 的任务（不停地重试、中止、重试）。因此您希望使用另外的进程处理(同时您的web应用程序没有使用 :doc:`always running 模式 <../deployment-to-production/making-aspnet-app-always-running>` )。
* *Do you have other suggestions? Please post them in the comment form below*.

您可以通过删除 ``BackgroundJobServer`` 类的实例化（如果您手动创建）或从OWIN配置类中删除 ``UseServer`` 方法的调用来停止主应用程序中的后台任务。

完成第一步后，您需要在另一个程序中处理这些后台任务，请参阅下列文档：

* :doc:`使用控制台应用程序 <processing-jobs-in-console-app>`
* :doc:`使用Windows服务 <processing-jobs-in-windows-service>`

.. admonition:: 同一个的任务存储执行一样的代码
   :class: note

   确保所有客户端/服务器使用 **同一个任务存储** 并 **具有相同的代码**。 如果客户端入队一个基于 ``SomeClass`` 的后台任务，但是服务器没有对应的代码,将简单地抛出一个性能异常。

如果有问题，您的客户端可以仅引用接口，而服务器实现接口。 (请参阅 :doc:`../background-methods/using-ioc-containers` 一节)

可疑情景
-------------------

* 您不想使用额外的线程池来处理后台任务 -- Hangfire Server使用 **自定义、单独和受限的线程池** 。
* 您正在使用 Web Farm 或者 Web Garden 并且不想面对同步问题 -- Hangfire Server 默认对 **Web Garden/Web Farm 友好** 。