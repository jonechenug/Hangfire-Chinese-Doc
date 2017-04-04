跟踪进度
======================

跟踪任务有两种方法：轮询和推送。轮询很容易理解，但推送是一种更舒适的方式，因为它可以避免对服务器的不必要的调用。此外， `SignalR <http://signalr.net>`_ 大大简化了推送。

我会给你一个简单的例子，客户端只需要检查一个任务的完成情况。您可以在 `Hangfire.Highlighter <https://github.com/odinserj/Hangfire.Highlighter>`_ 项目中看到完整的示例。

Highlighter有以下后台任务，通过下面的代码调用外部的web服务：

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

So, when we are rendering the code snippet that is not highlighted yet, we need to render a JavaScript that makes ajax calls with some interval to some controller action that returns the job status (completed or not) until the job was finished.

.. code-block:: c#

    public ActionResult CheckHighlighted(int snippetId)
    {
        var snippet = _db.Snippets.Find(snippetId);

        return snippet.HighlightedCode == null
            ? new HttpStatusCodeResult(HttpStatusCode.NoContent)
            : Content(snippet.HighlightedCode);
    }

When code snippet become highlighted, we can stop the polling and show the highlighted code. But if you want to track progress of your job, you need to perform extra steps:

* Add a column ``Status`` to the snippets table.
* Update this column during background work.
* Check this column in polling action.

But there is a better way.

Using server push with SignalR
-------------------------------

Why we need to poll our server? It can say when the snippet becomes highlighted himself. And `SignalR <http://signalr.net>`_, an awesome library to perform server push, will help us. If you don't know about this library, look at it, and you'll love it. Really.

I don't want to include all the code snippets here (you can look at the sources of this sample). I'll show you only the two changes that you need, and they are incredibly simple.

First, you need to add a hub:

.. code-block:: c#

    public class SnippetHub : Hub
    {
        public async Task Subscribe(int snippetId)
        {
            await Groups.Add(Context.ConnectionId, GetGroup(snippetId));

            // When a user subscribes a snippet that was already 
            // highlighted, we need to send it immediately, because
            // otherwise she will listen for it infinitely.
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

And second, you need to make a small change to your background job method:

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

And that's all! When user opens a page that contains unhighlighted code snippet, his browser connects to the server, subscribes for code snippet notification and waits for update notifications. When background job is about to be done, it sends the highlighted code to all subscribed users.

If you want to add progress tracking, just add it. No additional tables and columns required, only JavaScript function. This is an example of real and reliable asynchrony for ASP.NET applications without taking much effort to it.
