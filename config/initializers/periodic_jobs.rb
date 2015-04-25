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

Rails.configuration.after_initialize do
  if defined?(ActiveRecord::SessionStore) && Rails.configuration.session_store == ActiveRecord::SessionStore
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
    Shard.with_each_shard do
      SessionPersistenceToken.send_later_enqueue_args(:delete_all, { strand: "SessionPersistenceToken.delete_all:#{Shard.current.database_server.id}", max_attempts: 1 }, ['updated_at < ?', persistence_token_expire_after.ago])
    end
  end

  Delayed::Periodic.cron 'ExternalFeedAggregator.process', '*/30 * * * *' do
    Shard.with_each_shard do
      ExternalFeedAggregator.send_later_enqueue_args(:process, strand: "ExternalFeedAggregator.process:#{Shard.current.database_server.id}", max_attempts: 1)
    end
  end

  Delayed::Periodic.cron 'SummaryMessageConsolidator.process', '*/15 * * * *' do
    Shard.with_each_shard do
      SummaryMessageConsolidator.send_later_enqueue_args(:process, strand: "SummaryMessageConsolidator.process:#{Shard.current.database_server.id}", max_attempts: 1)
    end
  end

  Delayed::Periodic.cron 'CrocodocDocument.update_process_states', '*/5 * * * *' do
    if Canvas::Crocodoc.config
      Shard.with_each_shard do
        CrocodocDocument.send_later_enqueue_args(:update_process_states, strand: "CrocodocDocument.update_process_sets:#{Shard.current.database_server.id}", max_attempts: 1)
      end
    end
  end

  Delayed::Periodic.cron 'Reporting::CountsReport.process', '0 11 * * *' do
    Reporting::CountsReport.process
  end

  Delayed::Periodic.cron 'StreamItem.destroy_stream_items', '45 11 * * *' do
    Shard.with_each_shard do
      StreamItem.send_later_enqueue_args(:destroy_stream_items_using_setting, strand: "StreamItem.destroy_stream_items:#{Shard.current.database_server.id}", max_attempts: 1)
    end
  end

  if IncomingMailProcessor::IncomingMessageProcessor.run_periodically?
    Delayed::Periodic.cron 'IncomingMailProcessor::IncomingMessageProcessor#process', '*/1 * * * *' do
      imp = IncomingMailProcessor::IncomingMessageProcessor.new(IncomingMail::MessageHandler.new, ErrorReport::Reporter.new)
      IncomingMailProcessor::IncomingMessageProcessor.workers.times do |worker_id|
        imp.send_later_enqueue_args(:process,
                                    {strand: "IncomingMailProcessor::IncomingMessageProcessor#process:#{worker_id}", max_attempts: 1},
                                    {worker_id: worker_id})
      end
    end
  end

  Delayed::Periodic.cron 'ErrorReport.destroy_error_reports', '35 */1 * * *' do
    cutoff = Setting.get('error_reports_retain_for', 3.months.to_s).to_i
    if cutoff > 0
      Shard.with_each_shard do
        ErrorReport.send_later_enqueue_args(:destroy_error_reports, { strand: "ErrorReport.destroy_error_reports:#{Shard.current.database_server.id}", max_attempts: 1 }, cutoff.ago)
      end
    end
  end

  Delayed::Periodic.cron 'Alerts::DelayedAlertSender.process', '30 11 * * *', :priority => Delayed::LOW_PRIORITY do
    Shard.with_each_shard do
      Alerts::DelayedAlertSender.send_later_enqueue_args(:process, strand: "Alerts::DelayedAlertSender.process:#{Shard.current.database_server.id}", max_attempts: 1)
    end
  end

  Delayed::Periodic.cron 'Attachment.do_notifications', '*/10 * * * *', :priority => Delayed::LOW_PRIORITY do
    Shard.with_each_shard do
      Attachment.send_later_enqueue_args(:do_notifications, strand: "Attachment.do_notifications:#{Shard.current.database_server.id}", max_attempts: 1)
    end
  end

  Delayed::Periodic.cron 'Ignore.cleanup', '45 23 * * *' do
    Shard.with_each_shard do
      Ignore.send_later_enqueue_args(:cleanup, strand: "Ignore.cleanup:#{Shard.current.database_server.id}", max_attempts: 1)
    end
  end

  Delayed::Periodic.cron 'MessageScrubber.scrub_all', '0 0 * * *' do
    Shard.with_each_shard do
      MessageScrubber.send_later_enqueue_args(:scrub, strand: "MessageScrubber.scrub_all:#{Shard.current.database_server.id}", max_attempts: 1)
    end
  end

  Delayed::Periodic.cron 'DelayedMessageScrubber.scrub_all', '0 1 * * *' do
    Shard.with_each_shard do
      DelayedMessageScrubber.send_later_enqueue_args(:scrub, strand: "DelayedMessageScrubber.scrub_all:#{Shard.current.database_server.id}", max_attempts: 1)
    end
  end

  if BounceNotificationProcessor.enabled?
    Delayed::Periodic.cron 'BounceNotificationProcessor.process', '*/5 * * * *' do
      BounceNotificationProcessor.process
    end
  end

  # Create a partition 1 month in advance every month:
  Delayed::Periodic.cron 'Quizzes::QuizSubmissionEventPartitioner.process', '0 0 1 * *' do
    Shard.with_each_shard do
      Quizzes::QuizSubmissionEventPartitioner.process
    end
  end

  Dir[Rails.root.join('vendor', 'plugins', '*', 'config', 'periodic_jobs.rb')].each do |plugin_periodic_jobs|
    require plugin_periodic_jobs
  end
end
