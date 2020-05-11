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
  class ResendPlagiarismEventsAfterShardSplit
    EVENT_NAME = 'plagiarism_resubmit'.freeze

    def self.run(canvas_domain, start_time = 3.months.ago, end_time = Time.zone.now)
      raise 'start_time must be less than end_time' unless start_time < end_time

      trigger_plagiarism_resubmit_for(
        submissions_missing_reports(start_time, end_time),
        canvas_domain
      )

      trigger_plagiarism_resubmit_for(
        submissions_missing_scored_reports(start_time, end_time),
        canvas_domain
      )
    end

    # Retriggers the plagiarism resubmit event for the given
    # submission scope.
    def self.trigger_plagiarism_resubmit_for(submission_scope, canvas_domain)
      submission_scope.find_each do |submission|
        Canvas::LiveEvents.post_event_stringified(
          ResendPlagiarismEventsAfterShardSplit::EVENT_NAME,
          Canvas::LiveEvents.get_submission_data(submission),
          context_for_event(submission, canvas_domain)
        )
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
        preload({assignment: {context: :root_account}, user: :pseudonyms})
    end
    private_class_method :all_configured_submissions

    def self.context_for_event(submission, canvas_domain)
      context = Canvas::LiveEvents.amended_context(submission.context)
      context[:job_id] = "manual_plagiarism_resubmit:#{SecureRandom.uuid}"
      context[:user_login] = submission.user.pseudonyms&.first&.unique_id || submission.user.name
      context[:user_account_id] = submission.user.pseudonyms&.first&.global_account_id || submission.user.global_id
      context[:hostname] = "#{canvas_domain}.instructure.com"
      context[:context_role] = 'StudentEnrollment'
      context[:producer] = 'canvas'
      context
    end
    private_class_method :context_for_event
  end
end