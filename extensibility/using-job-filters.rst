使用任务过滤器
==================

所有任务都实现了 Chain-of-responsibility 模式并且可以像ASP.NET MVC操作过滤器一样被拦截。

**定义过滤器**

.. code-block:: c#

    public class LogEverythingAttribute : JobFilterAttribute,
        IClientFilter, IServerFilter, IElectStateFilter, IApplyStateFilter
    {
        private static readonly ILog Logger = LogProvider.GetCurrentClassLogger();

        public void OnCreating(CreatingContext context)
        {
            Logger.InfoFormat("Creating a job based on method `{0}`...", context.Job.Method.Name);
        }

        public void OnCreated(CreatedContext context)
        {
            Logger.InfoFormat(
                "Job that is based on method `{0}` has been created with id `{1}`",
                context.Job.Method.Name,
                context.BackgroundJob?.Id);
        }

        public void OnPerforming(PerformingContext context)
        {
            Logger.InfoFormat("Starting to perform job `{0}`", context.BackgroundJob.Id);
        }

        public void OnPerformed(PerformedContext context)
        {
            Logger.InfoFormat("Job `{0}` has been performed", context.BackgroundJob.Id);
        }

        public void OnStateElection(ElectStateContext context)
        {
            var failedState = context.CandidateState as FailedState;
            if (failedState != null)
            {
                Logger.WarnFormat(
                    "Job `{0}` has been failed due to an exception `{1}`",
                    context.BackgroundJob.Id,
                    failedState.Exception);
            }
        }

        public void OnStateApplied(ApplyStateContext context, IWriteOnlyTransaction transaction)
        {
            Logger.InfoFormat(
                "Job `{0}` state was changed from `{1}` to `{2}`",
                context.BackgroundJob.Id,
                context.OldStateName,
                context.NewState.Name);
        }

        public void OnStateUnapplied(ApplyStateContext context, IWriteOnlyTransaction transaction)
        {
            Logger.InfoFormat(
                "Job `{0}` state `{1}` was unapplied.", 
                context.BackgroundJob.Id, 
                context.OldStateName);
        }
    }

**使用过滤器**

像ASP.NET过滤器一样，您可以在方法，类和全局上应用过滤器：

.. code-block:: c#

    [LogEverything]
    public class EmailService
    {
        [LogEverything]
        public static void Send() { }
    }

    GlobalJobFilters.Filters.Add(new LogEverythingAttribute());
