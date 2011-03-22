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

if ActionController::Base.session_store == ActiveRecord::SessionStore
  expire_after = (Setting.from_config("session_store") || {})[:expire_after]
  expire_after ||= 1.day

  scheduler.cron '*/5 * * * *' do
    ActiveRecord::SessionStore::Session.delete_all(['updated_at < ?', expire_after.ago])
  end
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

scheduler.cron '45 11 * * *' do
  # we pass false for the touch_users argument, on the assumption that these
  # stream items that we delete aren't visible on the user's dashboard anymore
  # anyway, so there's no need to invalidate all the caches.
  StreamItem.send_later_enqueue_args(:destroy_stream_items, { :priority => Delayed::LOW_PRIORITY }, 4.weeks.ago, false)
end
