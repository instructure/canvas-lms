#
# Copyright (C) 2014 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

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

class PeriodicJobs
  def self.with_each_shard_by_database_in_region(klass, method, *args)
    Shard.with_each_shard(Shard.in_current_region) do
      klass.send_later_enqueue_args(method, {
          strand: "#{klass}.#{method}:#{Shard.current.database_server.id}",
          max_attempts: 1
      }, *args)
    end
  end
end

def with_each_shard_by_database(klass, method, *args)
  DatabaseServer.send_in_each_region(PeriodicJobs,
                                     :with_each_shard_by_database_in_region,
                                     {
                                       singleton: "periodic:region: #{klass}.#{method}",
                                       max_attempts: 1,
                                     }, klass, method, *args)
end

Rails.configuration.after_initialize do
  if defined?(ActiveRecord::SessionStore) && Rails.configuration.session_store == ActiveRecord::SessionStore
    expire_after = (ConfigFile.load("session_store") || {})[:expire_after]
    expire_after ||= 1.day

    Delayed::Periodic.cron 'ActiveRecord::SessionStore::Session.delete_all', '*/5 * * * *' do
      callback = -> { Canvas::Errors.capture_exception(:periodic_job, $ERROR_INFO) }
      Shard.with_each_shard(exception: callback) do
        ActiveRecord::SessionStore::Session.where('updated_at < ?', expire_after.seconds.ago).delete_all
      end
    end
  end

  persistence_token_expire_after = (ConfigFile.load("session_store") || {})[:expire_remember_me_after]
  persistence_token_expire_after ||= 1.month
  Delayed::Periodic.cron 'SessionPersistenceToken.delete_all', '35 11 * * *' do
    with_each_shard_by_database(SessionPersistenceToken, :delete_expired, persistence_token_expire_after)
  end

  Delayed::Periodic.cron 'ExternalFeedAggregator.process', '*/30 * * * *' do
    with_each_shard_by_database(ExternalFeedAggregator, :process)
  end

  Delayed::Periodic.cron 'SummaryMessageConsolidator.process', '*/15 * * * *' do
    with_each_shard_by_database(SummaryMessageConsolidator, :process)
  end

  Delayed::Periodic.cron 'CrocodocDocument.update_process_states', '*/10 * * * *' do
    if Canvas::Crocodoc.config && !Canvas::Plugin.value_to_boolean(Canvas::Crocodoc.config['disable_polling'])
      with_each_shard_by_database(CrocodocDocument, :update_process_states)
    end
  end

  Delayed::Periodic.cron 'Reporting::CountsReport.process', '0 11 * * 0' do
    Reporting::CountsReport.process
  end

  Delayed::Periodic.cron 'Account.update_all_update_account_associations', '0 10 * * 0' do
    with_each_shard_by_database(Account, :update_all_update_account_associations)
  end

  Delayed::Periodic.cron 'StreamItem.destroy_stream_items', '45 11 * * *' do
    with_each_shard_by_database(StreamItem, :destroy_stream_items_using_setting)
  end

  if IncomingMailProcessor::IncomingMessageProcessor.run_periodically?
    Delayed::Periodic.cron 'IncomingMailProcessor::IncomingMessageProcessor#process', '*/1 * * * *' do
      imp = IncomingMailProcessor::IncomingMessageProcessor.new(IncomingMail::MessageHandler.new, ErrorReport::Reporter.new)
      IncomingMailProcessor::IncomingMessageProcessor.workers.times do |worker_id|
        if IncomingMailProcessor::IncomingMessageProcessor.dedicated_workers_per_mailbox
          # Launch one per mailbox
          IncomingMailProcessor::IncomingMessageProcessor.mailbox_accounts.each do |account|
            imp.send_later_enqueue_args(:process,
                                        {singleton: "IncomingMailProcessor::IncomingMessageProcessor#process:#{worker_id}:#{account.address}", max_attempts: 1},
                                        {worker_id: worker_id, mailbox_account_address: account.address})
          end
        else
          # Just launch the one
          imp.send_later_enqueue_args(:process,
                                      {singleton: "IncomingMailProcessor::IncomingMessageProcessor#process:#{worker_id}", max_attempts: 1},
                                      {worker_id: worker_id})
        end
      end
    end
  end

  Delayed::Periodic.cron 'IncomingMailProcessor::Instrumentation#process', '*/5 * * * *' do
    IncomingMailProcessor::Instrumentation.process
  end

  Delayed::Periodic.cron 'ErrorReport.destroy_error_reports', '2-59/5 * * * *' do
    cutoff = Setting.get('error_reports_retain_for', 3.months.to_s).to_i
    if cutoff > 0
      with_each_shard_by_database(ErrorReport, :destroy_error_reports, cutoff.seconds.ago)
    end
  end

  Delayed::Periodic.cron 'Alerts::DelayedAlertSender.process', '30 11 * * *', priority: Delayed::LOW_PRIORITY do
    with_each_shard_by_database(Alerts::DelayedAlertSender, :process)
  end

  Delayed::Periodic.cron 'Attachment.do_notifications', '*/10 * * * *', priority: Delayed::LOW_PRIORITY do
    with_each_shard_by_database(Attachment, :do_notifications)
  end

  Delayed::Periodic.cron 'Ignore.cleanup', '45 23 * * *' do
    with_each_shard_by_database(Ignore, :cleanup)
  end

  Delayed::Periodic.cron 'MessageScrubber.scrub_all', '0 0 * * *' do
    with_each_shard_by_database(MessageScrubber, :scrub)
  end

  Delayed::Periodic.cron 'DelayedMessageScrubber.scrub_all', '0 1 * * *' do
    with_each_shard_by_database(DelayedMessageScrubber, :scrub)
  end

  Delayed::Periodic.cron 'ConversationBatchScrubber.scrub_all', '0 2 * * *' do
    with_each_shard_by_database(ConversationBatchScrubber, :scrub)
  end

  Delayed::Periodic.cron 'BounceNotificationProcessor.process', '*/5 * * * *' do
    DatabaseServer.send_in_each_region(
      BounceNotificationProcessor,
      :process,
      { run_current_region_asynchronously: true,
        singleton: 'BounceNotificationProcessor.process' }
    )
  end

  Delayed::Periodic.cron 'NotificationFailureProcessor.process', '*/5 * * * *' do
    DatabaseServer.send_in_each_region(
      NotificationFailureProcessor,
      :process,
      { run_current_region_asynchronously: true,
        singleton: 'NotificationFailureProcessor.process' }
    )
  end

  Delayed::Periodic.cron 'Quizzes::QuizSubmissionEventPartitioner.process', '0 0 * * *' do
    with_each_shard_by_database(Quizzes::QuizSubmissionEventPartitioner, :process)
  end

  Delayed::Periodic.cron 'Version::Partitioner.process', '0 0 * * *' do
    with_each_shard_by_database(Version::Partitioner, :process)
  end

  if AccountAuthorizationConfig::SAML.enabled?
    Delayed::Periodic.cron 'AccountAuthorizationConfig::SAML::MetadataRefresher.refresh_providers', '15 0 * * *' do
      with_each_shard_by_database(AccountAuthorizationConfig::SAML::MetadataRefresher,
                                  :refresh_providers)
    end

    AccountAuthorizationConfig::SAML::Federation.descendants.each do |federation|
      Delayed::Periodic.cron "AccountAuthorizationConfig::SAML::#{federation.class_name}.refresh_providers", '45 0 * * *' do
        DatabaseServer.send_in_each_region(federation,
                                    :refresh_providers,
                                    singleton: "AccountAuthorizationConfig::SAML::#{federation.class_name}.refresh_providers")
      end
    end
  end

  Delayed::Periodic.cron 'SisBatchErrors.cleanup_old_errors', '*/15 * * * *', priority: Delayed::LOW_PRIORITY do
    with_each_shard_by_database(SisBatchError, :cleanup_old_errors)
  end

  Delayed::Periodic.cron 'EnrollmentState.recalculate_expired_states', '*/5 * * * *', priority: Delayed::LOW_PRIORITY do
    with_each_shard_by_database(EnrollmentState, :recalculate_expired_states)
  end

  Delayed::Periodic.cron 'MissingPolicyApplicator.apply_missing_deductions', '*/5 * * * *', priority: Delayed::LOW_PRIORITY do
    with_each_shard_by_database(MissingPolicyApplicator, :apply_missing_deductions)
  end
end
