# frozen_string_literal: true

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
    EVENT_NAME = "plagiarism_resubmit"
    RESUBMIT_LIMIT = 100
    RESUBMIT_WAIT_TIME = 3.minutes

    def self.run(start_time: 3.months.ago, end_time: Time.zone.now, only_errors: false)
      # We're going to create all of the jobs that need to run with some far future run date
      # (so we know what they all are and we won't run them all at once and overwhelm our partners) and
      # then we're going to start the first one.
      batch_end_time = end_time
      loop do
        batch_start_time = resend_scope(start_time, batch_end_time, limit: RESUBMIT_LIMIT, only_errors:)
                           .pluck(:submitted_at)&.last
        break if batch_start_time.nil?

        schedule_resubmit_job_by_time(batch_start_time, batch_end_time, only_errors)
        batch_end_time = batch_start_time
      end
      schedule_next_job
    end

    def self.resend_scope(start_time, end_time, limit: nil, only_errors: false)
      raise "start_time must be less than end_time" unless start_time < end_time

      # this is a limit and order on the subquery scope so the union over the whole submissions table doesn't take forever
      submission_scope = all_configured_submissions(start_time, end_time).select(:id).order(submitted_at: :desc)
      submission_scope = submission_scope.limit(limit) if limit
      submission_scope = only_errors ? errors_report_scope(submission_scope) : missing_report_scope(submission_scope)
      union_scope = Submission.where("id in (#{submission_scope})").order(submitted_at: :desc)
      union_scope = union_scope.limit(limit) if limit
      union_scope
    end

    def self.missing_report_scope(scope)
      "(#{scope.joins(:attachment_associations)
      .joins("LEFT JOIN #{OriginalityReport.quoted_table_name}
              AS ors ON submissions.id = ors.submission_id
                    AND submissions.submitted_at = ors.submission_time
                    AND attachment_associations.attachment_id = ors.attachment_id")
      .where("ors.id IS NULL OR ors.workflow_state = 'pending'").to_sql})
      UNION
      (#{scope.where(submission_type: "online_text_entry")
      .joins("LEFT JOIN #{OriginalityReport.quoted_table_name}
            AS ors ON submissions.id = ors.submission_id
                  AND submissions.submitted_at = ors.submission_time
                  AND ors.attachment_id IS NULL")
      .where("ors.id IS NULL OR ors.workflow_state ='pending'").to_sql})"
    end

    def self.errors_report_scope(scope)
      "(#{scope.joins(:attachment_associations)
      .joins("INNER JOIN #{OriginalityReport.quoted_table_name}
              AS ors ON submissions.id = ors.submission_id
                    AND submissions.submitted_at = ors.submission_time
                    AND attachment_associations.attachment_id = ors.attachment_id
                    AND ors.workflow_state = 'error'").to_sql})
      UNION
      (#{scope.where(submission_type: "online_text_entry")
        .joins("INNER JOIN #{OriginalityReport.quoted_table_name}
                AS ors ON submissions.id = ors.submission_id
                      AND submissions.submitted_at = ors.submission_time
                      AND ors.attachment_id IS NULL
                      AND ors.workflow_state = 'error'").to_sql})"
    end

    def self.schedule_resubmit_job_by_time(start_time, end_time, only_errors)
      DataFixup::ResendPlagiarismEvents.delay(priority: Delayed::LOWER_PRIORITY,
                                              strand: "plagiarism_event_resend",
                                              run_at: 1.year.from_now)
                                       .trigger_plagiarism_resubmit_by_time(start_time, end_time, only_errors)
    end

    def self.schedule_next_job
      Delayed::Job.where(strand: "plagiarism_event_resend", locked_at: nil)
                  .order(:id).first&.update(run_at: RESUBMIT_WAIT_TIME.from_now)
    end

    # Retriggers the plagiarism resubmit event for the given
    # submission scope.
    def self.trigger_plagiarism_resubmit_by_time(start_time, end_time, only_errors = false)
      # Since we set all of the jobs to be run in a year, we need to schedule the next job to run
      # so they run every few minutes
      schedule_next_job

      resend_scope(start_time, end_time, only_errors:)
        .preload(course: :root_account, assignment: :assignment_configuration_tool_lookups, user: :pseudonyms).each do |submission|
        Canvas::LiveEvents.post_event_stringified(
          ResendPlagiarismEvents::EVENT_NAME,
          Canvas::LiveEvents.get_submission_data(submission),
          context_for_event(submission)
        )
      end
    end

    # Returns all submissions for assignments associated with
    # a plagiarism platform assignment
    def self.all_configured_submissions(start_time, end_time)
      Submission.active
                .where(submitted_at: start_time...end_time)
                .where(AssignmentConfigurationToolLookup.where("assignment_id = submissions.assignment_id").arel.exists)
    end
    private_class_method :all_configured_submissions

    def self.context_for_event(submission)
      context = Canvas::LiveEvents.amended_context(submission.course)
      context[:job_id] = "manual_plagiarism_resubmit:#{SecureRandom.uuid}"
      context[:user_login] = submission.user.pseudonyms&.first&.unique_id || submission.user.name
      context[:user_account_id] = submission.user.pseudonyms&.first&.global_account_id || submission.user.global_id
      context[:hostname] = submission.course.root_account.domain
      context[:context_role] = "StudentEnrollment"
      context[:producer] = "canvas"
      context
    end
    private_class_method :context_for_event
  end
end
