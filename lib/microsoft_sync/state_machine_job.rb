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
# in a console) `run_synchronously`. Either of these can take an initial
# mem_state argument, which is useful if you have different flavors of jobs that
# need to run on the same strand (and not start until the one currently
# running/retrying has finished). IMPORTANT: if you use non-primitives in
# initial_mem_state, deduping of backlogged jobs will not work; see
# find_delayed_job (and its usage)
#
# The job runs on a strand tied to the state_record which means only one job
# may be running at a time. In addition, if new a job is started while a job
# is in-progress, it will be rescheduled for after the current job finishes
# (unless another new job with the same initial_mem_state is already eneueued)
#
# STATES:
# When a job is running:
#   job_state_record.workflow_state is "running"
# When a job has hit a retriable error:
#   job_state_record.workflow_state is "retrying"
#   job_state_record.job_state is information about the step that failed,
#       and data it may need to continue where it left off. There may be other
#       temporary data in the DB with retry info (e.g. saved with a stash block
#       and cleaned up in after_failure()). If a record has been deleted and then
#       restored, job_state should be set to {restored: true}
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
        super()
        @cause = cause
      end
    end

    # NOTE: if we ever use this class for something besides SyncerSteps, we may want
    # to change this and the capture_exception() calls which just group by microsoft_sync_smj
    STATSD_PREFIX = "microsoft_sync.smj"

    # job_state_record is assumed to be a model with the following used here:
    #  - global_id
    #  - job_state
    #  - workflow_state
    #    -> update_unless_deleted() -- atomically updates attributes if workflow_state != 'deleted'
    #    -> state can be: pending, running, retrying, errored, completed, deleted
    #    -> deleted? method
    #  - last_error
    # See MicrosoftSync::Group
    attr_reader :job_state_record

    # steps_object defines the steps of the job and has the following:
    #   max_retries() -- for entire job
    #   max_delay() -- delays (`Retry`s or `DelayedNextStep`s) will be clipped
    #     to this length of time.
    #   after_failure() -- called when a job fails (unretriable error
    #     raised, or a Retry happens past max_retries), or when a stale
    #     job is restarted. Can be used to clean up state, e.g. state stored in
    #     stash_block
    #   after_complete() -- called when a step returns COMPLETE. Note: this is
    #     run even if the state record has been deleted since we last checked.
    #   steps methods with two arguments: memory_state, job_state_data.
    #     (If you don't need all the arguments, you can also make the methods
    #     take 0 or 1 arguments). The steps methods should return a NextStep or
    #     Retry object or COMPLETE (see below), or you can raise an error to
    #     signal a unretriable error. It is recommended you begin step methods
    #     with `step_` to make them obvious.
    #   step_initial(initial_memory_state, job_state_data) -- the initial step
    attr_reader :steps_object

    def initialize(job_state_record, steps_object)
      @job_state_record = job_state_record
      @steps_object = steps_object
    end

    # NextStep, Retry, IGNORE, and COMPLETE are structs to signal what to do next. Use
    # these as the return values for your step_foobar() methods.

    # Signals that this step of the job succeeded.
    # memory_state is passed into the next step.
    class NextStep
      attr_reader :step, :memory_state

      def initialize(step, memory_state = nil)
        @step = step or raise InternalError
        @memory_state = memory_state
      end
    end

    class DelayedNextStep
      attr_reader :step, :delay_amount, :job_state_data

      def initialize(step, delay_amount, job_state_data = nil)
        @step = step or raise InternalError
        @delay_amount = delay_amount
        @job_state_data = job_state_data
      end
    end

    # Return this when your job is done:
    Complete = Class.new
    COMPLETE = Complete.new

    # Ignore this job. Like COMPLETE, but if there is a last_error, that will not overwritten
    # and workflow_state will be set [back] to errored
    Ignore = Class.new
    IGNORE = Ignore.new

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

    # If something goes way wrong with jobs (or they are paused for some time), after this period
    # of time we may clear the state and restart the job. See `job_is_stale?`
    STALE_JOB_TIME = 1.day

    # SEE ALSO Errors::GracefulCancelError
    # Raise an error with this mixin in your job if you want to cancel &
    # cleanup & update workflow_state, but not bubble up the error (e.g. create
    # a Delayed::Job::Failed). Can be mixed in to normal errors or `PublicError`s

    INITIAL_STEP = :step_initial

    # Mostly used for debugging. May use sleep!
    def run_synchronously(initial_mem_state = nil)
      run_with_delay(initial_mem_state:, synchronous: true)
    rescue IRB::Abort => e
      update_state_record_to_errored_and_cleanup(error: e, step: nil)
      raise
    end

    def run_later(initial_mem_state = nil)
      run_with_delay(initial_mem_state:)
    end

    private

    def run(step, initial_mem_state, synchronous = false)
      job_state = job_state_record.job_state

      # Record has been deleted since we were enqueued:
      return if job_state_record.deleted?

      step_from_job_state = job_state&.dig(:step)

      # Normal case: job continuation, or new job (step==nil) and no other job in-progress
      if step&.to_s == step_from_job_state&.to_s
        return run_main_loop(step, initial_mem_state, job_state&.dig(:data), synchronous)
      end

      unless step.nil?
        # Current job is not a new job, and the job state is either nil or says
        # we're in some differnt step.  This normally shouldn't happen since we
        # prevent jobs from running at once (see where we check for stale
        # state/jobs and reset state below). This can happen if jobs were
        # paused for longer than STALE_JOB_TIME and a new job in the queue
        # comes and wipes out the state
        #
        # It can also happen if the job_state_record was deleted and then restored
        # while the job was waiting to be retried. Check that case here and ignore.
        # job_state will get reset the next time the job completes/retries/errors.
        if job_state&.dig(:restored)
          log { "In-progress job starting again but job state record was deleted & restored since" }
          return
        end

        err = InternalError.new(
          "Job step doesn't match state: #{step.inspect} != #{step_from_job_state.inspect}. " \
          "workflow_state: #{job_state_record.workflow_state}, job_state: #{job_state.inspect}"
        )
        capture_exception(err)
        raise err
      end

      currently_retrying_job = find_delayed_job(strand) do |args|
        args&.first&.to_s == step_from_job_state.to_s
      end

      if currently_retrying_job.nil? || job_is_stale?(currently_retrying_job)
        # Trying to run a new job, old job has possibly stalled. Clean up and start over.
        statsd_increment(:stalled, step_from_job_state)
        steps_object.after_failure
        job_state_record.update!(job_state: nil)
        run_main_loop(nil, initial_mem_state, nil, synchronous)
        return
      end

      # Else: there's a currently retrying (waiting) job; backlog this job to run after it.
      # If there's already a backlogged job with the same initial_mem_state, this one can
      # be dropped.
      if find_delayed_job(strand) { |args| args == [nil, initial_mem_state] }
        log { "Dropping duplicate job, initial_mem_state=#{initial_mem_state.inspect}" }
      else
        if synchronous
          raise InternalError, "A job is waiting to be retried; use run_later() to enqueue another"
        end

        delay(strand:, run_at: currently_retrying_job.run_at + 1)
          .run(nil, initial_mem_state)
      end
    end

    # Only to be used from run(), which does other checks before kicking off main loop:
    def run_main_loop(current_step, initial_mem_state, job_state_data, synchronous)
      return unless job_state_record&.update_unless_deleted(workflow_state: :running)

      current_step ||= INITIAL_STEP
      memory_state = initial_mem_state

      loop do
        # TODO: consider checking if group object is deleted before every step (INTEROP-6621)
        log { "running step #{current_step}" }
        begin
          result = steps_object.send(current_step.to_sym, memory_state, job_state_data)
        rescue => e
          if e.is_a?(Errors::GracefulCancelError)
            statsd_increment(:cancel, current_step, e)
            update_state_record_to_errored_and_cleanup(error: e, step: current_step)
            return
          else
            statsd_increment(:failure, current_step, e)
            update_state_record_to_errored_and_cleanup(error: e, step: current_step, capture: e)
            raise
          end
        end

        log { "step #{current_step} finished with #{result.class.name.split("::").last}" }
        case result
        when Complete
          job_state_record&.update_unless_deleted(
            workflow_state: :completed, job_state: nil, last_error: nil
          )
          steps_object.after_complete
          statsd_increment(:complete, current_step)
          return
        when Ignore
          new_state = job_state_record&.last_error ? :errored : :complete
          job_state_record&.update_unless_deleted(workflow_state: new_state, job_state: nil)
          statsd_increment(:ignored, current_step)
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
          raise InternalError, "Step returned #{result.inspect}, expected COMPLETE/NextStep/Retry/IGNORE"
        end
      end
    end

    def statsd_increment(bucket, step, error = nil)
      tags = { category: error&.class&.name&.tr(":", "_"), microsoft_sync_step: step.to_s }.compact
      InstStatsd::Statsd.increment("#{STATSD_PREFIX}.#{bucket}", tags:)
    end

    def log(&)
      Rails.logger.info { "#{strand}: #{yield}" }
    end

    def strand
      @strand ||= "#{self.class.name}:#{job_state_record.class.name}:#{job_state_record.global_id}"
    end

    def run_with_delay(step: nil, delay_amount: nil, initial_mem_state: nil, synchronous: false)
      # step is used for retry/delay next step; initial_mem_state only for new jobs
      raise InternalError unless step.nil? || initial_mem_state.nil?

      if synchronous
        sleep delay_amount if delay_amount
        run(step, initial_mem_state, true)
        return
      end

      delay(strand:, run_at: delay_amount&.seconds&.from_now)
        .run(step, initial_mem_state)
    end

    def update_state_record_to_errored_and_cleanup(error:, step:, capture: nil)
      error_report_id = capture && capture_exception(capture)[:error_report]
      error_msg = MicrosoftSync::Errors.serialize(error, step:)
      job_state_record&.update_unless_deleted(
        workflow_state: :errored, job_state: nil,
        last_error: error_msg, last_error_report_id: error_report_id
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
      Canvas::Errors.capture(err, { tags: { type: "microsoft_sync_smj" } }, :error)
    end

    def handle_delayed_next_step(delayed_next_step, synchronous)
      return unless update_state_record_to_retrying(
        step: delayed_next_step.step,
        data: delayed_next_step.job_state_data,
        retries_by_step: job_state_record.reload.job_state&.dig(:retries_by_step)
      )

      run_with_delay(
        step: delayed_next_step.step,
        delay_amount: clip_delay_amount(delayed_next_step.delay_amount),
        synchronous:
      )
    end

    # Ensure delay amount is not too long so as to make the job look stalled:
    def clip_delay_amount(delay_amount)
      max_delay = steps_object.max_delay.to_f
      delay_amount = delay_amount.to_f
      delay_amount.clamp(0, max_delay).tap do |clipped|
        log { "Clipped delay #{delay_amount} to #{clipped}" } unless clipped.equal?(delay_amount)
      end
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
        e = retry_object.error

        if e.is_a?(Errors::GracefulCancelError)
          statsd_increment(:cancel, current_step, e)
          update_state_record_to_errored_and_cleanup(error: e, step: current_step)
          return
        else
          statsd_increment(:final_retry, current_step, e)
          update_state_record_to_errored_and_cleanup(
            error: e,
            step: current_step,
            capture: RetriesExhaustedError.new(e)
          )
          raise e
        end
      end

      statsd_increment("retry", current_step, retry_object.error)

      retry_object.stash_block&.call

      return unless update_state_record_to_retrying(
        step: retry_step,
        data: retry_object.job_state_data,
        retries_by_step: retries_by_step.merge(retry_step.to_s => retries + 1),
        # for debugging only:
        retried_on_error: "#{retry_object.error.class}: #{retry_object.error.message}"
      )

      delay_amount = retry_object.delay_amount
      delay_amount = delay_amount[retries] || delay_amount.last if delay_amount.is_a?(Array)
      delay_amount = clip_delay_amount(delay_amount) if delay_amount
      log { "handle_retry #{current_step} -> #{retry_step} - #{delay_amount}" }

      run_with_delay(step: retry_step, delay_amount:, synchronous:)
    end

    # Find a delayed job on the strand with arguments that match the selector
    # IMPORTANT: To avoid unnecessary database loads of the state_record
    # object, this uses YAML to avoid instantiating objects in the YAML;
    # this also means that the args passed into the selector will be only Ruby
    # primitives. So if you use non-primitives in initial_mem_state, duplicate
    # job detection won't work.
    def find_delayed_job(strand, &args_selector)
      Delayed::Job.where(strand:).find_each.find do |job|
        job != Delayed::Worker.current_job && args_selector[
          YAML.unsafe_load(job.handler)["args"]
        ]
      end
    end

    # In case something is really weird with jobs, this prevents us from staying in that
    # weird state forever. A job is considered stale if its run_at time is too far in the past
    # (if jobs are paused or bogged down, this could happen a little, but not too much) or too
    # far in the past (past max_delay)
    def job_is_stale?(job)
      job && (job.run_at < STALE_JOB_TIME.ago ||
              job.run_at > steps_object.max_delay.from_now)
    end
  end
end
