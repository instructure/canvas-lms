# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

module BroadcastPolicies
  class SubmissionPolicy
    attr_reader :submission

    def initialize(submission)
      @submission = submission
    end

    def should_dispatch_assignment_submitted_late?
      course.available? &&
        !submission.group_broadcast_submission &&
        just_submitted_late? &&
        submission.submitted? &&
        submission.has_submission? &&
        submission.late? &&
        !assignment.deleted?
    end

    def should_dispatch_assignment_submitted?
      dispatch = course.available? &&
                 just_submitted? &&
                 submission.submitted? &&
                 submission.has_submission? &&
                 # don't send a submitted message because we already sent
                 # an :assignment_submitted_late message
                 !submission.late? &&
                 !is_a_resubmission?

      dispatch &&= new_quiz_submission? if assignment.quiz_lti?

      dispatch
    end

    def should_dispatch_assignment_resubmitted?
      dispatch = course.available? &&
                 is_a_resubmission? &&
                 submission.has_submission? &&
                 # don't send a resubmitted message because we already sent an
                 # :assignment_submitted_late message.
                 !submission.late?

      dispatch &&= submission.submitted? unless assignment.quiz_lti?

      dispatch
    end

    def should_dispatch_group_assignment_submitted_late?
      course.available? &&
        submission.group_broadcast_submission &&
        just_submitted_late? &&
        submission.submitted? &&
        submission.late?
    end

    def should_dispatch_submission_graded?
      broadcasting_grades? &&
        user_has_visibility? &&
        (submission.changed_state_to(:graded) || (grade_updated? && graded_recently?))
    end

    def should_dispatch_submission_grade_changed?
      broadcasting_grades? &&
        submission.graded_at &&
        !graded_recently? &&
        grade_updated? &&
        user_has_visibility?
    end

    def should_dispatch_submission_posted?
      return false unless submission.grade_posting_in_progress && context_sendable?

      submission.reload
      posted_recently?
    end

    private

    def context_sendable?
      course.available? && !course.concluded?
    end

    def broadcasting_grades?
      context_sendable? &&
        submission.posted? &&
        assignment.published? &&
        submission.quiz_submission_id.nil? &&
        user_active_or_invited?
    end

    def assignment
      submission.assignment
    end

    def course
      assignment.context
    end

    def just_submitted?
      submission.changed_state_to(:submitted)
    end

    def just_submitted_late?
      just_submitted? || submission.saved_change_to_submitted_at?
    end

    def is_a_resubmission?
      return new_quiz_resubmission? if assignment.quiz_lti?

      submission.submitted_at_before_last_save &&
        submission.saved_change_to_submitted_at?
    end

    def new_quiz_submission?
      # New quizzes updates Submission records in several
      # ways. The most reliable way to check if a submission
      # was submitted for the first time is seeing if the
      # workflow state transitioned from unsubmitted -> submitted.
      submission.saved_change_to_workflow_state == [
        Submission.workflow_states.unsubmitted,
        Submission.workflow_states.submitted
      ]
    end

    def new_quiz_resubmission?
      is_resubmission = submission.saved_change_to_url?

      # If the previous url value was blank it indicates a submission, not resubmission
      is_resubmission &&= submission.saved_change_to_url.first.present?

      # Make sure the new URL value was not used previously. If it was, this is not a resubmission
      is_resubmission && submission.submission_history.none? { |s| s.url == submission.saved_change_to_url.last }
    end

    def grade_updated?
      submission.changed_in_state(:graded, fields: [:score, :grade])
    end

    def graded_recently?
      submission.assignment_graded_in_the_last_hour?
    end

    def posted_recently?
      submission.posted_at.present? && submission.posted_at > 1.hour.ago
    end

    def user_has_visibility?
      AssignmentStudentVisibility.where(assignment_id: submission.assignment_id, user_id: submission.user_id).any?
    end

    def user_active_or_invited?
      course.student_enrollments.where(user_id: submission.user_id).preload(:enrollment_state).to_a.any? { |e| e.active? || e.invited? }
    end
  end
end
