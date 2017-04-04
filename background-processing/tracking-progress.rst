跟踪进度（翻译地不好）
======================

跟踪任务有两种方法：轮询和推送。轮询很容易理解，但推送是一种更舒适的方式，因为它可以避免对服务器的不必要的调用。此外， `SignalR <http://signalr.net>`_ 大大简化了推送。

我会给你一个简单的例子，客户端只需要检查一个任务的完成情况。您可以在 `Hangfire.Highlighter <https://github.com/odinserj/Hangfire.Highlighter>`_ 项目中看到完整的示例。

Highlighter有以下后台任务，通过调用外部的web服务来突出代码的执行程度：

.. code-block:: c#

    public void Highlight(int snippetId)
    {
        var snippet = _dbContext.CodeSnippets.Find(snippetId);
        if (snippet == null) return;

        snippet.HighlightedCode = HighlightSource(snippet.SourceCode);
        snippet.HighlightedAt = DateTime.UtcNow;

        _dbContext.SaveChanges();
    }

轮询工作状态
-------------------------

举一个足够简单的例子，任务未完成意味着什么？意味着 ``HighlightedCode`` 属性 *为空* 。任务已完成又意味着什么？意味着指定的属性 *有值* 。

所以当还没执行到对应的代码时，我们需要在任务完成之前写一个JavaScript脚本来定时使用ajax访问控制器， 获取任务的状态（完成与否）。

.. code-block:: c#

    public ActionResult CheckHighlighted(int snippetId)
    {
        var snippet = _db.Snippets.Find(snippetId);

        return snippet.HighlightedCode == null
            ? new HttpStatusCodeResult(HttpStatusCode.NoContent)
            : Content(snippet.HighlightedCode);
    }

当执行到对应的代码片段时，我们可以停止轮询。但是如果要跟踪工作的进度，您需要执行额外的步骤：

* 添加 ``Status`` 字段到 snippets 表。
* 在后台任务执行期间更新此字段。
* 在轮询操作中检查该字段。

但是有一个更好的方法。

使用SignalR推送 
-------------------------------

为什么我们需要轮询我们的服务器？因为它可以代表代码执行到哪里。 而我们也可以使用 `SignalR <http://signalr.net>`_, 一个了不起的推送利器。如果您不了解这个工具，我相信您在了解后一定会喜欢的。

我不想在这里列出所有的代码(你可以看一下下面这个例子的代码). 我只指出需要知道的两处不同，就可以发现十分简单。

First, you need to add a hub:

.. code-block:: c#

    public class SnippetHub : Hub
    {
        public async Task Subscribe(int snippetId)
        {
            await Groups.Add(Context.ConnectionId, GetGroup(snippetId));

            // 当执行到对应的代码就会触发订阅
            // 我们只需马上推送
            // 否则会不停地监听
            using (var db = new HighlighterDbContext())
            {
                var snippet = await db.CodeSnippets
                    .Where(x => x.Id == snippetId && x.HighlightedCode != null)
                    .SingleOrDefaultAsync();

                if (snippet != null)
                {
                    Clients.Client(Context.ConnectionId)
                        .highlight(snippet.Id, snippet.HighlightedCode);
                }
            }
        }

        public static string GetGroup(int snippetId)
        {
            return "snippet:" + snippetId;
        }
    }

其次，您需要对后台任务的方法做一个小的改动：

.. code-block:: c#

    public void HighlightSnippet(int snippetId)
    {
        ...
        _dbContext.SaveChanges();

        var hubContext = GlobalHost.ConnectionManager
            .GetHubContext<SnippetHub>();

        hubContext.Clients.Group(SnippetHub.GetGroup(snippet.Id))
            .highlight(snippet.HighlightedCode);
    }

就这样！当用户打开对应的页面时，他的浏览器连接到服务器，订阅通知并等待更新通知。当后台任务即将完成时，它会将对应的信息发送给所有订阅的用户。

这样如果要跟踪进度，不需要额外的表和字段，只需要使用JavaScript。这是ASP.NET应用程序真正可靠的一个异步通讯例子，同时不需要太多的操作。
