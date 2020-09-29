#
# Copyright (C) 2020 - present Instructure, Inc.
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

# this datafixup is not intended to have a corresponding migration. it will be
# manually applied

module DataFixup
  # This fixup is meant to be run after a shard split.
  #
  # Plagiarism platform live event subscriptions use
  # the shard ID of events to deliver the event to
  # the correct customer.
  #
  # This data fixup triggers a plagiarism_resubmit
  # event for all submissions that do not have a
  # scored originality report
  #
  # A start and end time may also be supplied.
  # If specified, only submission that were
  # submitted in the time range will have events
  # retriggered.
  class ResendPlagiarismEvents
    EVENT_NAME = 'plagiarism_resubmit'.freeze

    def self.run(start_time = 3.months.ago, end_time = Time.zone.now)
      raise 'start_time must be less than end_time' unless start_time < end_time

      schedule_resubmit_job(
        submissions_missing_reports(start_time, end_time).union(
          submissions_missing_scored_reports(start_time, end_time)
        )
      )
    end

    def self.schedule_resubmit_job(scope)
      _, wait_time = Setting.get('trigger_plagiarism_resubmit', '100,180').split(',').map(&:to_i)
      run_at = Delayed::Job.where(strand: "plagiarism_event_resend").order(:run_at).last&.run_at
      DataFixup::ResendPlagiarismEvents.send_later_if_production_enqueue_args(
        :trigger_plagiarism_resubmit_for,
        {
          priority: Delayed::LOWER_PRIORITY,
          strand: "plagiarism_event_resend",
          run_at: (run_at &.+ wait_time.seconds.from_now) || Time.zone.now
        },
        scope
      )
    end

    # Retriggers the plagiarism resubmit event for the given
    # submission scope.
    def self.trigger_plagiarism_resubmit_for(submission_scope)
      limit, _ = Setting.get('trigger_plagiarism_resubmit', '100,180').split(',').map(&:to_i)
      submission_scope = submission_scope.order(:id)
      limited_scope = submission_scope.limit(limit)
      limited_scope.each do |submission|
        Canvas::LiveEvents.post_event_stringified(
          ResendPlagiarismEvents::EVENT_NAME,
          Canvas::LiveEvents.get_submission_data(submission),
          context_for_event(submission)
        )
      end

      # since we're sending these in limited batches, we need to check if we have more
      # and start a new job for the next batch if there are more
      last_batch_id = limited_scope.last&.id
      if last_batch_id &.< submission_scope.maximum(:id)
        schedule_resubmit_job(submission_scope.where("id > ?", last_batch_id))
      end
    end
    private_class_method :trigger_plagiarism_resubmit_for

    # Returns all submissions configured with a plagiarism
    # platform assignment that lack a scored originality
    # report.
    def self.submissions_missing_scored_reports(start_time, end_time)
      all_configured_submissions(start_time, end_time).joins(:originality_reports).
        where.not(originality_reports: { workflow_state: 'scored' })
    end
    private_class_method :submissions_missing_scored_reports

    # Returns all submissions configured with a plagiarism
    # platform assignment that lack an do not have any
    # originality reports
    def self.submissions_missing_reports(start_time, end_time)
      all_configured_submissions(start_time, end_time).left_outer_joins(:originality_reports).
        where(originality_reports: {id: nil})
    end
    private_class_method :submissions_missing_reports

    # Returns all submissions for assignments associated with
    # a plagiarism platform assignment
    def self.all_configured_submissions(start_time, end_time)
      Submission.active.
        where.not(workflow_state: 'unsubmitted').
        where(submitted_at: start_time..end_time).
        joins(assignment: :assignment_configuration_tool_lookups).
        preload(course: :root_account, assignment: :assignment_configuration_tool_lookups, user: :pseudonyms)
    end
    private_class_method :all_configured_submissions

    def self.context_for_event(submission)
      context = Canvas::LiveEvents.amended_context(submission.course)
      context[:job_id] = "manual_plagiarism_resubmit:#{SecureRandom.uuid}"
      context[:user_login] = submission.user.pseudonyms&.first&.unique_id || submission.user.name
      context[:user_account_id] = submission.user.pseudonyms&.first&.global_account_id || submission.user.global_id
      context[:hostname] = submission.course.root_account.domain
      context[:context_role] = 'StudentEnrollment'
      context[:producer] = 'canvas'
      context
    end
    private_class_method :context_for_event
  end
end