# Defines periodic jobs run by DelayedJobs.
#
# Scheduling is done by rufus-scheduler
#
# You should only use "cron" type jobs, not "every". Cron jobs have deterministic
# times to run which help across daemon restarts, and distributing periodic
# jobs across multiple job servers.
#
# Periodic jobs default to low priority. You can override this in the arguments
# passed to Delayed::Periodic.cron

if ActionController::Base.session_store == ActiveRecord::SessionStore
  expire_after = (Setting.from_config("session_store") || {})[:expire_after]
  expire_after ||= 1.day

  Delayed::Periodic.cron 'ActiveRecord::SessionStore::Session.delete_all', '*/5 * * * *' do
    Shard.with_each_shard do
      ActiveRecord::SessionStore::Session.delete_all(['updated_at < ?', expire_after.ago])
    end
  end
end

persistence_token_expire_after = (Setting.from_config("session_store") || {})[:expire_remember_me_after]
persistence_token_expire_after ||= 1.month
Delayed::Periodic.cron 'SessionPersistenceToken.delete_all', '35 11 * * *' do
  Shard.with_each_shard do
    SessionPersistenceToken.delete_all(['updated_at < ?', persistence_token_expire_after.ago])
  end
end

Delayed::Periodic.cron 'ExternalFeedAggregator.process', '*/30 * * * *' do
  Shard.with_each_shard do
    ExternalFeedAggregator.process
  end
end

Delayed::Periodic.cron 'SummaryMessageConsolidator.process', '*/15 * * * *' do
  Shard.with_each_shard do
    SummaryMessageConsolidator.process
  end
end

Delayed::Periodic.cron 'Attachment.process_scribd_conversion_statuses', '*/5 * * * *' do
  Shard.with_each_shard do
    Attachment.process_scribd_conversion_statuses
  end
end

Delayed::Periodic.cron 'Twitter processing', '*/15 * * * *' do
  Shard.with_each_shard do
    TwitterSearcher.process
    TwitterUserPoller.process
  end
end

Delayed::Periodic.cron 'Reporting::CountsReport.process', '0 11 * * *' do
  Reporting::CountsReport.process
end

Delayed::Periodic.cron 'StreamItem.destroy_stream_items', '45 11 * * *' do
  Shard.with_each_shard do
    StreamItem.destroy_stream_items_using_setting
  end
end

if Mailman.config.poll_interval == 0 && Mailman.config.ignore_stdin == true
  Delayed::Periodic.cron 'IncomingMessageProcessor.process', '*/1 * * * *' do
    IncomingMessageProcessor.process
  end
end

if PageView.page_view_method == :cache
  # periodically pull new page views off the cache and insert them into the db
  Delayed::Periodic.cron 'PageView.process_cache_queue', '*/1 * * * *' do
    Shard.with_each_shard do
      PageView.send_later_enqueue_args(:process_cache_queue, :singleton => "PageView.process_cache_queue:#{Shard.current.description}")
    end
  end
end

Delayed::Periodic.cron 'ErrorReport.destroy_error_reports', '35 */1 * * *' do
  cutoff = Setting.get('error_reports_retain_for', 3.months.to_s).to_i
  if cutoff > 0
    Shard.with_each_shard do
      ErrorReport.destroy_error_reports(cutoff.ago)
    end
  end
end

if Delayed::Stats.enabled?
  Delayed::Periodic.cron 'Delayed::Stats.cleanup', '0 11 * * *' do
    Delayed::Stats.cleanup
  end
end

Delayed::Periodic.cron 'Alert.process', '30 11 * * *', :priority => Delayed::LOW_PRIORITY do
  Shard.with_each_shard do
    Alert.process
  end
end
