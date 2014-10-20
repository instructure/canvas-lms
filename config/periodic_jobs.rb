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

if Rails.configuration.session_store == ActiveRecord::SessionStore
  expire_after = (ConfigFile.load("session_store") || {})[:expire_after]
  expire_after ||= 1.day

  Delayed::Periodic.cron 'ActiveRecord::SessionStore::Session.delete_all', '*/5 * * * *' do
    Shard.with_each_shard(exception: -> { ErrorReport.log_exception(:periodic_job, $!) }) do
      ActiveRecord::SessionStore::Session.delete_all(['updated_at < ?', expire_after.ago])
    end
  end
end

persistence_token_expire_after = (ConfigFile.load("session_store") || {})[:expire_remember_me_after]
persistence_token_expire_after ||= 1.month
Delayed::Periodic.cron 'SessionPersistenceToken.delete_all', '35 11 * * *' do
  Shard.with_each_shard(exception: -> { ErrorReport.log_exception(:periodic_job, $!) }) do
    SessionPersistenceToken.delete_all(['updated_at < ?', persistence_token_expire_after.ago])
  end
end

Delayed::Periodic.cron 'ExternalFeedAggregator.process', '*/30 * * * *' do
  Shard.with_each_shard(exception: -> { ErrorReport.log_exception(:periodic_job, $!) }) do
    ExternalFeedAggregator.process
  end
end

Delayed::Periodic.cron 'SummaryMessageConsolidator.process', '*/15 * * * *' do
  Shard.with_each_shard do
    SummaryMessageConsolidator.send_later_enqueue_args(:process, strand: "SummaryMessageConsolidator.process:#{Shard.current.database_server.id}", max_attempts: 1)
  end
end

Delayed::Periodic.cron 'CrocodocDocument.update_process_states', '*/5 * * * *' do
  if Canvas::Crocodoc.config
    Shard.with_each_shard(exception: -> { ErrorReport.log_exception(:periodic_job, $!) }) do
      CrocodocDocument.update_process_states
    end
  end
end

Delayed::Periodic.cron 'Reporting::CountsReport.process', '0 11 * * *' do
  Reporting::CountsReport.process
end

Delayed::Periodic.cron 'StreamItem.destroy_stream_items', '45 11 * * *' do
  Shard.with_each_shard(exception: -> { ErrorReport.log_exception(:periodic_job, $!) }) do
    StreamItem.destroy_stream_items_using_setting
  end
end

if IncomingMailProcessor::IncomingMessageProcessor.run_periodically?
  Delayed::Periodic.cron 'IncomingMailProcessor::IncomingMessageProcessor.process', '*/1 * * * *' do
    IncomingMailProcessor::IncomingMessageProcessor.new(IncomingMail::MessageHandler.new, ErrorReport::Reporter.new).process
  end
end

Delayed::Periodic.cron 'ErrorReport.destroy_error_reports', '35 */1 * * *' do
  cutoff = Setting.get('error_reports_retain_for', 3.months.to_s).to_i
  if cutoff > 0
    Shard.with_each_shard(exception: -> { ErrorReport.log_exception(:periodic_job, $!) }) do
      ErrorReport.destroy_error_reports(cutoff.ago)
    end
  end
end

if Delayed::Stats.enabled?
  Delayed::Periodic.cron 'Delayed::Stats.cleanup', '0 11 * * *' do
    Delayed::Stats.cleanup
  end
end

Delayed::Periodic.cron 'Alerts::DelayedAlertSender.process', '30 11 * * *', :priority => Delayed::LOW_PRIORITY do
  Shard.with_each_shard do
    Alerts::DelayedAlertSender.process
  end
end

Delayed::Periodic.cron 'Attachment.do_notifications', '*/10 * * * *', :priority => Delayed::LOW_PRIORITY do
  Shard.with_each_shard(exception: -> { ErrorReport.log_exception(:periodic_job, $!) }) do
    Attachment.do_notifications
  end
end

Delayed::Periodic.cron 'Ignore.cleanup', '45 23 * * *' do
  Shard.with_each_shard do
    Ignore.send_later_enqueue_args(:cleanup, :singleton => "Ignore.cleanup:#{Shard.current.id}")
  end
end

Delayed::Periodic.cron 'MessageScrubber.scrub_all', '0 0 * * *' do
  Shard.with_each_shard(exception: -> { ErrorReport.log_exception(:periodic_job, $!) }) do
    MessageScrubber.new.scrub
  end
end

Delayed::Periodic.cron 'DelayedMessageScrubber.scrub_all', '0 1 * * *' do
  Shard.with_each_shard(exception: -> { ErrorReport.log_exception(:periodic_job, $!) }) do
    DelayedMessageScrubber.new.scrub
  end
end

if BounceNotificationProcessor.enabled?
  Delayed::Periodic.cron 'BounceNotificationProcessor.process', '*/5 * * * *' do
    BounceNotificationProcessor.process
  end
end

Dir[Rails.root.join('vendor', 'plugins', '*', 'config', 'periodic_jobs.rb')].each do |plugin_periodic_jobs|
  require plugin_periodic_jobs
end
