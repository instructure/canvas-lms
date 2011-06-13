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

  Delayed::Periodic.cron 'ActiveRecord::SessionStore::Session.delete_all', '*/5 * * * *' do
    ActiveRecord::SessionStore::Session.delete_all(['updated_at < ?', expire_after.ago])
  end
end

Delayed::Periodic.cron 'ExternalFeedAggregator.process', '*/30 * * * *' do
  ExternalFeedAggregator.send_later_enqueue_args(:process, { :priority => Delayed::LOW_PRIORITY, :max_attempts => 1 })
end

Delayed::Periodic.cron 'SummaryMessageConsolidator.process', '*/15 * * * *' do
  SummaryMessageConsolidator.send_later_enqueue_args(:process, { :priority => Delayed::LOW_PRIORITY, :max_attempts => 1 })
end

Delayed::Periodic.cron 'Attachment.process_scribd_conversion_statuses', '*/5 * * * *' do
  Attachment.send_later_enqueue_args(:process_scribd_conversion_statuses, { :priority => Delayed::LOW_PRIORITY, :max_attempts => 1 })
end

Delayed::Periodic.cron 'Twitter processing', '*/15 * * * *' do
  TwitterSearcher.send_later_enqueue_args(:process, { :priority => Delayed::LOW_PRIORITY, :max_attempts => 1 })
  TwitterUserPoller.send_later_enqueue_args(:process, { :priority => Delayed::LOW_PRIORITY, :max_attempts => 1 })
end

Delayed::Periodic.cron 'Reporting::CountsReport.process', '0 11 * * *' do
  Reporting::CountsReport.send_later_enqueue_args(:process, { :priority => Delayed::LOW_PRIORITY, :max_attempts => 1 })
end

Delayed::Periodic.cron 'StreamItem.destroy_stream_items', '45 11 * * *' do
  # we pass false for the touch_users argument, on the assumption that these
  # stream items that we delete aren't visible on the user's dashboard anymore
  # anyway, so there's no need to invalidate all the caches.
  StreamItem.send_later_enqueue_args(:destroy_stream_items, { :priority => Delayed::LOW_PRIORITY, :max_attempts => 1 }, 4.weeks.ago, false)
end

if Mailman.config.poll_interval == 0 && Mailman.config.ignore_stdin == true
  Delayed::Periodic.cron 'IncomingMessageProcessor.process', '*/1 * * * *' do
    IncomingMessageProcessor.send_later_enqueue_args(:process, { :priority => Delayed::LOW_PRIORITY, :max_attempts => 1 })
  end
end

if PageView.page_view_method == :cache
  # periodically pull new page views off the cache and insert them into the db
  Delayed::Periodic.cron 'PageView.process_cache_queue', '*/5 * * * *' do
    PageView.send_later_enqueue_args(:process_cache_queue,
                                     { :priority => Delayed::LOW_PRIORITY, :max_attempts => 1 })
  end
end

Delayed::Periodic.cron 'ErrorReport.destroy_error_reports', '35 */1 * * *' do
  cutoff = Setting.get('error_reports_retain_for', 3.months.to_s).to_i
  if cutoff > 0
    ErrorReport.send_later_enqueue_args(:destroy_error_reports, { :priority => Delayed::LOW_PRIORITY, :max_attempts => 1 }, cutoff.ago)
  end
end

if Delayed::Stats.enabled?
  Delayed::Periodic.cron 'Delayed::Stats.cleanup', '0 11 * * *' do
    Delayed::Stats.send_later_enqueue_args(:cleanup, :priority => Delayed::LOW_PRIORITY, :max_attempts => 1)
  end
end

