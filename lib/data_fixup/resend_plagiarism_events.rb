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
    EVENT_NAME = 'plagiarism_resubmit'.freeze

    def self.run(start_time = 3.months.ago, end_time = Time.zone.now)
      limit, = Setting.get('trigger_plagiarism_resubmit', '100,180').split(',').map(&:to_i)

      # We're going to create all of the jobs that need to run with some far future run date
      # (so we know what they all are and we won't run them all at once and overwhelm our partners) and
      # then we're going to start the first one.
      batch_end_time = end_time
      loop do
        batch_start_time = resend_scope(start_time, batch_end_time).limit(limit).pluck(:submitted_at)&.last
        break if batch_start_time.nil?

        schedule_resubmit_job_by_time(batch_start_time, batch_end_time)
        batch_end_time = batch_start_time
      end
      run_next_job
    end

    def self.resend_scope(start_time, end_time)
      raise 'start_time must be less than end_time' unless start_time < end_time

      submission_scope = all_configured_submissions(start_time, end_time)
      submission_scope.joins(:attachment_associations).
        joins("LEFT JOIN #{OriginalityReport.quoted_table_name}
                AS ors ON submissions.id = ors.submission_id
                      AND submissions.submitted_at = ors.submission_time
                      AND attachment_associations.attachment_id = ors.attachment_id
                      AND ors.workflow_state <> 'scored'").
        union(
          submission_scope.where(submission_type: 'online_text_entry').
          joins("LEFT JOIN #{OriginalityReport.quoted_table_name}
                  AS ors ON submissions.id = ors.submission_id
                        AND submissions.submitted_at = ors.submission_time
                        AND ors.attachment_id IS NULL
                        AND ors.workflow_state <> 'scored'")
        ).order(submitted_at: :desc).
        preload(course: :root_account, assignment: :assignment_configuration_tool_lookups, user: :pseudonyms)
    end

    def self.schedule_resubmit_job_by_time(start_time, end_time)
      DataFixup::ResendPlagiarismEvents.send_later_if_production_enqueue_args(
        :trigger_plagiarism_resubmit_by_time,
        {
          priority: Delayed::LOWER_PRIORITY,
          strand: "plagiarism_event_resend",
          run_at: 1.year.from_now
        },
        start_time,
        end_time
      )
    end

    def self.run_next_job
      _, wait_time = Setting.get('trigger_plagiarism_resubmit', '100,180').split(',').map(&:to_i)
      Delayed::Job.where(strand: "plagiarism_event_resend", locked_at: nil).
        order(:id).first&.update_attributes(run_at: wait_time.seconds.from_now)
    end

    # Retriggers the plagiarism resubmit event for the given
    # submission scope.
    def self.trigger_plagiarism_resubmit_by_time(start_time, end_time)
      resend_scope(start_time, end_time).each do |submission|
        Canvas::LiveEvents.post_event_stringified(
          ResendPlagiarismEvents::EVENT_NAME,
          Canvas::LiveEvents.get_submission_data(submission),
          context_for_event(submission)
        )
      end
    ensure
      # After we finish any job, we need to set the next one to run after the specified
      # wait time
      run_next_job
    end

    # Returns all submissions for assignments associated with
    # a plagiarism platform assignment
    def self.all_configured_submissions(start_time, end_time)
      Submission.active.
        where(submitted_at: start_time...end_time).
        where("EXISTS(?)", AssignmentConfigurationToolLookup.where("assignment_id = submissions.assignment_id"))
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