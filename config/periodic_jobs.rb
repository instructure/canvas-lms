# Defines periodic jobs run by DelayedJobs.
# 
# Scheduling is done by rufus-scheduler
# 
# Note that periodic jobs must currently only run on a single machine.
# TODO: Create some sort of coordination so that these jobs can be
# triggered from any of the jobs processing nodes.

# Nearly all of these should just create new DelayedJobs to be run immediately.
# The only exception should be with something that runs quickly and doesn't
# create any AR objects.

# You should only use "cron" type jobs, not "every". Cron jobs have deterministic
# times to run which help across daemon restarts.

scheduler.cron '*/5 * * * *' do
  ActiveRecord::SessionStore::Session.delete_all(['created_at < ? OR updated_at < ?', 3.weeks.ago, 1.day.ago])
end

scheduler.cron '*/30 * * * *' do
  ExternalFeedAggregator.send_later_enqueue_args(:process, { :priority => Delayed::LOW_PRIORITY })
end

scheduler.cron '*/15 * * * *' do
  SummaryMessageConsolidator.send_later_enqueue_args(:process, { :priority => Delayed::LOW_PRIORITY })
end

scheduler.cron '*/5 * * * *' do
  Attachment.send_later_enqueue_args(:process_scribd_conversion_statuses, { :priority => Delayed::LOW_PRIORITY })
end

scheduler.cron '*/15 * * * *' do
  TwitterSearcher.send_later_enqueue_args(:process, { :priority => Delayed::LOW_PRIORITY })
  TwitterUserPoller.send_later_enqueue_args(:process, { :priority => Delayed::LOW_PRIORITY })
end

scheduler.cron '0 11 * * *' do
  Reporting::CountsReport.send_later_enqueue_args(:process, { :priority => Delayed::LOW_PRIORITY })
end
