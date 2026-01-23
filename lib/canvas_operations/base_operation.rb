# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

require "active_support/callbacks"

require_relative "errors"
require_relative "base_concerns/settings"
require_relative "base_concerns/callbacks"
require_relative "base_concerns/progress_tracking"

module CanvasOperations
  # BaseOperation
  #
  # Base operation class that acts as a parent for all canvas operations.
  #
  # Operations are bound to a single Switchman shard to ensure consistency during
  # execution (example: data cached in instance variables may not be valid if the currentshard changes).
  #
  # Subclasses should override the `execute` method to implement their specific operation logic.
  # They can also override methods like `singleton`, `context`, and others to customize behavior
  #
  # Subclasses can also use `<before|after|around>_run` and `<before|after|around>_failure` callbacks to hook into
  # the operation lifecycle.
  #
  # This class provides a consistent set of behaviors to all operations:
  #   - Binding operations to a single shard
  #   - Consistent logging via `#log_message`
  #   - Progress tracking via the `Progress` model
  #   - Standardized error handling and reporting
  #   - Integration with InstStatsd for event emission (start, complete, failure)
  #   - Configurable settings via class-level `setting` definitions, backed by the `Setting` model
  #
  # See `./data_fixup.rb` for an example subclass implementation.
  class BaseOperation
    extend CanvasOperations::BaseConcerns::Settings
    extend CanvasOperations::BaseConcerns::Callbacks
    extend CanvasOperations::BaseConcerns::ProgressTracking

    class << self
      def log_message(message, level: :info)
        Rails.logger.public_send(level, "[#{name}] #{message}")
      end

      def operation_name
        name.demodulize.underscore.tr("/", "_")
      end
    end

    define_callbacks :run, :failure

    before_run :report_run_start
    after_run :report_run_complete
    after_failure :report_run_failed

    attr_reader :switchman_shard, :time
    attr_accessor :results

    def initialize(switchman_shard: nil)
      @switchman_shard = switchman_shard || Shard.current
      @time = Time.now.utc.to_i
      @results = {}
    end

    # Schedules the current operation to be executed asynchronously.
    #
    # This method uses `Progress#process_job` to enqueue the operation for later execution,
    # which handles associating the Progress with a delayed job and managing the Progress lifecycle.
    #
    # Progress records are attached to the operation's context, which is the cluster primary administrative account
    # by default.
    #
    # Operations are enqueued with a singleton job that includes the current shard ID. This means that at
    # most only one operation can be enqueued or running per shard at a time. If new operations are enqueued
    # while another is still pending or running, the new operation will replace the previous one.
    #
    # @note Subclasses should not override this method. Instead, they should implement their logic in `#execute`.
    #
    # @return [Object] The result of the `process_job` invocation, which may vary depending on the implementation.
    def run_later
      # Enforce a common singleton prefix for easy identification
      final_job_options = job_options.tap { |options| options[:singleton] = "operations/#{name}/#{options[:singleton]}" if options[:singleton] }

      unless use_progress_tracking?
        log_message("Progress tracking is disabled; running operation without Progress tracking.", level: :debug)
        delay_if_production(**final_job_options).run
        return
      end

      progress.process_job(
        self,
        :run,
        final_job_options
      )
    end

    # Executes the operation with the provided Progress tracker.
    #
    # This method sets the current progress, ensures the operation is running on the correct shard,
    # executes the main operation logic, marks the progress as complete, and updates the progress
    # with the operation's results.
    #
    # @note Subclasses should not override this method. Instead, they should implement their logic in `#execute`.
    #       If custom logic is needed before, after, or around the execution, subclasses can use the provided
    #       callbacks (`before_run`, `after_run`, `around_run`).
    # @note When using `run_later`, the progress tracker is managed automatically by `Progress#process_job` unless
    #       progress_tracking is disabled.
    #
    # @note If the operation raises `Errors::InvalidOperationTarget`, the operation gracefully fails, runs any
    #       failure callbacks, and marks the progress as failed.
    #
    # @param new_progress [Progress] The progress tracker object to be used for this operation. Note that
    #   `Progress#process_job` manages this automatically when using `run_later`.
    # @raise [Errors::WrongShard] If the operation is run on an incorrect shard.
    # @return [void]
    def run(new_progress = nil)
      @progress = new_progress if new_progress

      run_callbacks :run do
        unless Shard.current == switchman_shard
          raise Errors::WrongShard, "Operation is being run on the wrong shard. Expected #{switchman_shard.id}, got #{Shard.current.id}"
        end

        execute

        complete_progress
      end
    rescue Errors::InvalidOperationTarget => e
      log_message("Operation failed due to invalid operation target: #{e.message}", level: :error)
      log_message("Note that the above error is being rescued; if this is a migration, other migrations can still continue.", level: :info)

      results[:error] = e.message

      fail_with_error!
    end

    # Marks the operation as failed and updates the progress with the current results.
    #
    # When `#run_later` is used, the Progress lifecycle is managed automatically, and this method
    # will be called as part of the failure handling.
    #
    # @note Subclasses should not override this method. Instead, they can use failure callbacks
    #
    # @return [void]
    def fail_with_error!
      run_callbacks :failure do
        fail_progress
      end
    end

    protected

    def log_message(...)
      self.class.log_message(...)
    end

    def name
      self.class.operation_name
    end

    # The main logic of the operation.
    #
    # Subclasses should override this method to implement their specific operation behavior.
    def execute
      log_message("Executing base operation - no-op")
    end

    # The singleton string used when enqueuing the operation's delayed job
    #
    # See https://github.com/instructure/inst-jobs?tab=readme-ov-file#singleton-jobs for more details on singleton jobs.
    #
    # Subclasses can override this method to provide different singleton values if needed.
    def singleton
      "shards/#{switchman_shard.id}"
    end

    def job_options
      opts = { singleton:, on_conflict: :overwrite }
      opts[:on_permanent_failure] = :fail_with_error! unless use_progress_tracking?
      opts
    end

    def context
      @context ||= begin
        if Rails.env.test?
          Account.default
        else
          # by default use the cluster primary account as the context.
          # Subclasses can override this to provide different contexts.
          switchman_shard.database_server.primary_shard&.activate do
            Account.root_accounts.where(external_status: ["administrative", "free_for_teachers"]).active.first ||
              Account.default
          end
        end
      rescue => e
        log_message("Error determining context account: #{e.message}", level: :error)
        Account.default
      end
    end

    def cluster
      switchman_shard.database_server.id || "unknown"
    end

    def progress
      @progress ||= context&.progresses&.find_or_create_by!(tag: progress_tag)
    end

    def in_test_environment_migration?
      Rails.env.test? && ActiveRecord::Base.in_migration
    end

    def report_message(title:, message:, alert_type: :success)
      log_message("#{title}: #{message}")

      InstStatsd::Statsd.event(
        "#{name}: #{title}",
        "#{name} #{message}",
        tags: event_tags,
        type: name,
        alert_type:
      )
    end

    private

    def use_progress_tracking?
      return false if in_test_environment_migration?

      progress_tracking? && !context.nil?
    end

    def settings_for(name, default:)
      self.class.setting_for(name, default:, cluster:)
    end

    def progress_tag
      "#{singleton}/time/#{time}/#{self.class.to_s.underscore}"
    end

    def complete_progress
      unless use_progress_tracking?
        log_message("Progress tracking is disabled; skipping progress completion.", level: :debug)
        return
      end

      completed = progress.complete

      # If the operation is not running in the context of a delayed job, we need to manually set the workflow state to
      # completed because the progress never transitioned from queued to running automatically.
      progress.workflow_state = "completed" unless completed
      progress.update!(results:)
    end

    def fail_progress
      unless use_progress_tracking?
        log_message("Progress tracking is disabled; skipping progress failure.", level: :debug)
        return
      end

      progress.fail
      progress.update!(results:)
    end

    def event_tags
      { cluster:, shard: switchman_shard.id }
    end

    def report_run_start
      log_message("Starting Run", level: :debug)

      InstStatsd::Statsd.event(
        "#{name} started",
        "#{name} operation for shard #{switchman_shard.id} started",
        tags: event_tags,
        type: name,
        alert_type: :success
      )
    end

    def report_run_complete
      log_message("Completed Run", level: :debug)

      InstStatsd::Statsd.event(
        "#{name} completed",
        "#{name} operation for shard #{switchman_shard.id} completed",
        tags: event_tags,
        type: name,
        alert_type: :success
      )
    end

    def report_run_failed
      log_message("Run Failed", level: :error)
      log_message("Check progress record errors: #{progress.global_id}", level: :error) if use_progress_tracking?

      InstStatsd::Statsd.event(
        "#{name} failed",
        "#{name} operation #{name} failed",
        tags: event_tags,
        type: name,
        alert_type: :error
      )
    end
  end
end
