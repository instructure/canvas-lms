# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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
#

# Object which extracts the logic of a multi-step job which may retry at each
# step of the job. Each step may need to pass on data to the next step; if any
# step fails, it may be retried, stashing data in job_state on a record or
# somewhere else (see stash_block below).
#
# After initializing, you will want to run with `run_later` or (for debugging
# in a console) `run_synchronously`.
#
# The job runs on a strand tied to the state_record which means only one job
# may be running at a time. In addition, if new a job is started while a job
# is in-progress, it will be dropped (see #run)
#
# STATES:
# When a job is running:
#   job_state_record.workflow_state is "running"
# When a job has hit a retriable error:
#   job_state_record.workflow_state is "retrying"
#   job_state_record.job_state is information about the step that failed,
#       and data it may need to continue where it left off. There may be other
#       temporary data in the DB with retry info (e.g. saved with a stash block
#       and cleaned up in after_failure())
# After a job has hit a final error (error raised, or max `Retry`s surpassed):
#   job_state_record.workflow_state is "errored"
#   job_state_record.last_error will have a user-friendly/safe error message
#   job_state_record.job_state will be clear
# After a job has completed successfully
#   job_state_record.workflow_state is "completed"
#   job_state_record.last_error, job_state will be clear
#
module MicrosoftSync
  class StateMachineJob
    class InternalError < ArgumentError; end
    class RetriesExhaustedError < StandardError
      attr_reader :cause

      def initialize(cause)
        @cause = cause
      end
    end

    # NOTE: if we ever use this class for something besides SyncerSteps, we may want
    # to change this and the capture_exception() calls which just group by microsoft_sync_smj
    STATSD_PREFIX = 'microsoft_sync.smj'

    # job_state_record is assumed to be a model with the following used here:
    #  - job_state
    #  - workflow_state
    #    -> update_unless_deleted() -- atomically updates attributes if workflow_state != 'deleted'
    #    -> state can be: pending, running, retrying, errored, completed, deleted
    #    -> deleted? method
    #  - last_error
    # See MicrosoftSync::Group
    attr_reader :job_state_record

    # steps_object defines the steps of the job and has the following:
    #   initial_step() -- string
    #   max_retries() -- for entire job
    #   restart_job_after_inactivity() -- staleness time, after which job is
    #     considered to be stalled and new jobs run will restart the job
    #     instead of being ignored. should be significantly longer than your
    #     longest Retry `delay_amount`
    #   two arguments: memory_state, job_state_data.
    #     (If you don't need all the arguments, you can also make the methods
    #     take 0 or 1 arguments). They should return a NextStep or Retry object
    #     or COMPLETE (see below), or you can raise an error to signal a
    #     unretriable error.
    #   after_failure() -- called when a job fails (unretriable error
    #     raised, or a Retry happens past max_retries), or when a stale
    #     job is restarted. Can be used to clean up state, e.g. state stored in
    #     stash_block
    #   after_complete() -- called when a step returns COMPLETE. Note: this is
    #     run even if the state record has been deleted since we last checked.
    attr_reader :steps_object

    def initialize(job_state_record, steps_object)
      @job_state_record = job_state_record
      @steps_object = steps_object
    end

    # NextStep, Retry, and COMPLETE are structs to signal what to do next. Use
    # these as the return values for your step_foobar() methods.

    # Signals that this step of the job succeeded.
    # memory_state is passed into the next step.
    class NextStep
      attr_reader :step, :memory_state
      def initialize(step, memory_state=nil)
        @step = step or raise InternalError
        @memory_state = memory_state
      end
    end

    class DelayedNextStep
      attr_reader :step, :delay_amount, :job_state_data
      def initialize(step, delay_amount, job_state_data=nil)
        @step = step or raise InternalError
        @delay_amount = delay_amount
        @job_state_data = job_state_data
      end
    end

    class Complete; end

    # Return this when your job is done:
    COMPLETE = Complete.new

    # Signals that this step of the job failed, but the job may be retriable.
    #
    # If the job has already surpassed the max number of retries, `error` will be
    # raised and handled like any non-retriable error (the job will fail, the
    # job_state_record's workflow_state will be set to error and error will be
    # put in last_error, and we will call after_failure()).
    #
    # Otherwise, a retry job will be enqueued; job_state_data will be written
    # into the job_state field of the job and passed into the same step when the
    # job runs again. If the data you need to save off is too big to fit in
    # job_state, you can pass in a block, which will run only if the max number
    # of retries has not been exceeded.
    #
    # To retry starting at a different step, you can also pass in "step".
    #
    class Retry
      attr_reader :error, :delay_amount, :job_state_data, :step, :stash_block
      def initialize(error:, delay_amount: nil, job_state_data: nil, step: nil, &stash_block)
        @error = error
        @delay_amount = delay_amount
        @job_state_data = job_state_data
        @stash_block = stash_block
        @step = step
      end
    end

    # Raise an error with this mixin in your job if you want to cancel &
    # cleanup & update workflow_state, but not bubble up the error (e.g. create
    # a Delayed::Job::Failed). Can be mixed in to normal errors or `PublicError`s
    module GracefulCancelErrorMixin; end

    # Mostly used for debugging. May use sleep!
    def run_synchronously(step=nil)
      run_with_delay(step, synchronous: true)
    end

    def run_later
      run_with_delay
    end

    private

    def run(step, synchronous=false)
      job_state = job_state_record.job_state

      # Record has been deleted since we were enqueued:
      return if job_state_record.deleted?

      step_from_job_state = job_state&.dig(:step)

      # Normal case: job continuation, or new job (step==nil) and no other job in-progress
      if step&.to_s == step_from_job_state&.to_s
        return run_main_loop(step, job_state&.dig(:data), synchronous)
      end

      unless step.nil?
        # Current job is not a new job, and the job state is either nil or says
        # we're in some differnt step.
        # This normally shouldn't happen since we prevent jobs from running at once.
        # This could happen if a job's retry time is longer than restart_job_after_inactivity, since
        # a new job could start over and reset the state before the continuation job runs.
        err = InternalError.new(
          "Job step doesn't match state: #{step.inspect} != #{step_from_job_state.inspect}. " \
          "workflow_state: #{job_state_record.workflow_state}, job_state: #{job_state.inspect}"
        )
        capture_exception(err)
        raise err
      end

      updated_at = job_state&.dig(:updated_at)
      if updated_at && updated_at < steps_object.restart_job_after_inactivity.ago
        # Trying to run a new job, old job has possibly stalled. Clean up and start over.
        statsd_increment(:stalled, step_from_job_state)
        steps_object.after_failure
        job_state_record.update!(job_state: nil)
        run_main_loop(nil, nil, synchronous)
      end

      # else: Trying to run a new job while old job in-progress. Do nothing, i.e., drop this job.
    end

    # Only to be used from run(), which does other checks before kicking off main loop:
    def run_main_loop(current_step, job_state_data, synchronous)
      return unless job_state_record&.update_unless_deleted(workflow_state: :running)

      current_step ||= steps_object.initial_step
      memory_state = nil

      loop do
        # TODO: consider checking if group object is deleted before every step (INTEROP-6621)
        log { "running step #{current_step}" }
        begin
          result = steps_object.send(current_step.to_sym, memory_state, job_state_data)
        rescue => e
          update_state_record_to_errored_and_cleanup(e)
          if e.is_a?(GracefulCancelErrorMixin)
            statsd_increment(:cancel, current_step, e)
            return
          else
            statsd_increment(:failure, current_step, e)
            capture_exception(e)
            raise
          end
        end

        log { "step #{current_step} finished with #{result.class.name}" }
        case result
        when Complete
          job_state_record&.update_unless_deleted(
            workflow_state: :completed, job_state: nil, last_error: nil
          )
          steps_object.after_complete
          statsd_increment(:complete)
          return
        when NextStep
          current_step, memory_state = result.step, result.memory_state
          job_state_data = nil
        when DelayedNextStep
          handle_delayed_next_step(result, synchronous)
          return
        when Retry
          handle_retry(result, current_step, synchronous)
          return
        else
          raise InternalError, "Step returned #{result.inspect}, expected COMPLETE/NextStep/Retry"
        end
      end
    end

    def statsd_increment(bucket, step=nil, error=nil)
      tags = {category: error&.class&.name, microsoft_sync_step: step&.to_s}.compact
      InstStatsd::Statsd.increment("#{STATSD_PREFIX}.#{bucket}", tags: tags)
    end

    def log(&_blk)
      Rails.logger.info { "#{strand}: #{yield}" }
    end

    def strand
      @strand ||= "#{self.class.name}:#{job_state_record.class.name}:#{job_state_record.id}"
    end

    def run_with_delay(step=nil, delay_amount=nil, synchronous: false)
      if synchronous
        sleep delay_amount if delay_amount
        run(step, true)
        return
      end

      self.delay(strand: strand, run_at: delay_amount&.seconds&.from_now).run(step)
    end

    def update_state_record_to_errored_and_cleanup(error)
      error_msg = MicrosoftSync::Errors.user_facing_message(error)
      job_state_record&.update_unless_deleted(
        workflow_state: :errored, last_error: error_msg, job_state: nil
      )
      steps_object.after_failure
    end

    def update_state_record_to_retrying(new_job_state)
      job_state_record&.update_unless_deleted(
        workflow_state: :retrying,
        job_state: new_job_state.merge(updated_at: Time.zone.now)
      )
    end

    def capture_exception(err)
      Canvas::Errors.capture(err, {tags: {type: 'microsoft_sync_smj'}}, :error)
    end

    def handle_delayed_next_step(delayed_next_step, synchronous)
      return unless update_state_record_to_retrying(
        step: delayed_next_step.step,
        data: delayed_next_step.job_state_data,
        retries_by_step: job_state_record.reload.job_state&.dig(:retries_by_step),
      )

      run_with_delay(
        delayed_next_step.step, delayed_next_step.delay_amount, synchronous: synchronous
      )
    end

    # Raises the error if we have passed the retry limit
    # Does nothing if workflow_state has since been set to deleted
    # Otherwise sets the job_state to keep track of (step, data, retries) and
    # kicks off a retry
    def handle_retry(retry_object, current_step, synchronous)
      retry_step = retry_object.step || current_step

      job_state = job_state_record.reload.job_state

      retries_by_step = job_state&.dig(:retries_by_step) || {}
      retries = retries_by_step[retry_step.to_s] || 0


      if retries >= steps_object.max_retries
        update_state_record_to_errored_and_cleanup(retry_object.error)
        statsd_increment(:final_retry, current_step, retry_object.error)
        capture_exception(RetriesExhaustedError.new(retry_object.error))
        raise retry_object.error
      end

      statsd_increment('retry', current_step, retry_object.error)

      retry_object.stash_block&.call

      return unless update_state_record_to_retrying(
        step: retry_step,
        data: retry_object.job_state_data,
        retries_by_step: retries_by_step.merge(retry_step.to_s => retries + 1),
        # for debugging only:
        retried_on_error: "#{retry_object.error.class}: #{retry_object.error.message}",
      )

      delay_amount = retry_object.delay_amount
      delay_amount = delay_amount[retries] || delay_amount.last if delay_amount.is_a?(Array)
      log { "handle_retry #{current_step} -> #{retry_step} - #{delay_amount}" }

      run_with_delay(retry_step, delay_amount, synchronous: synchronous)
    end
  end
end
