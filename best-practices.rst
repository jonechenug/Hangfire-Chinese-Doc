最佳实践
===============

处理后台任务与常规调用方法有很大的不同。本指南旨在帮助让您的后台任务平稳有效地运行。本文基于 `这篇博客文章 <http://odinserj.net/2014/05/10/are-your-methods-ready-to-run-in-background/>`_。

使任务参数小而简单
------------------------------------

方法（任务）在调用之前会被序列化。使用 `TypeConverter` 类将参数转换为JSON字符串。如果您有复杂的实体和/或大对象; 包括数组，最好将它们放入数据库，然后只将其标识(id)传递给后台任务。

错误例子:

.. code-block:: c#

   public void Method(Entity entity) { }

可以换成这样:

.. code-block:: c#

   public void Method(int entityId) { }

让后台任务可重试
---------------------------------------

`重试 <https://en.wikipedia.org/wiki/Reentrant_(subroutine)>`_ 意味着可以在执行过程中中断，然后再安全地调用。中断可能是由许多不同的事情引起的(即异常，服务端关闭),而Hangfire将尝试重试多次。

如果没有合理安排，将遇到很多问题。例如，如果您有一个发送的电子邮件的后台任务，SMTP服务却发生错误，则应该以邮件发送出去的事件作为结束标志。

错误的例子：

.. code-block:: c#

   public void Method()
   {
       _emailService.Send("person@exapmle.com", "Hello!");
   }

可以换成这样:

.. code-block:: c#

   public void Method(int deliveryId)
   {
       if (_emailService.IsNotDelivered(deliveryId))
       {
           _emailService.Send("person@example.com", "Hello!");
           _emailService.SetDelivered(deliveryId);
       }
   }

*未完待续。。。*
