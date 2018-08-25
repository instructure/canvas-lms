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
      submission.late?
    end

    def should_dispatch_assignment_submitted?
      course.available? &&
      just_submitted? &&
      submission.submitted? &&
      submission.has_submission? &&
      # don't send a submitted message because we already sent an :assignment_submitted_late message
      !submission.late?
    end

    def should_dispatch_assignment_resubmitted?
      course.available? &&
      submission.submitted? &&
      is_a_resubmission? &&
      submission.has_submission? &&
      # don't send a resubmitted message because we already sent a :assignment_submitted_late message.
      !submission.late?
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

    private
    def broadcasting_grades?
      course.available? &&
      !course.concluded? &&
      !assignment.muted? &&
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
      (just_submitted? || submission.saved_change_to_submitted_at?)
    end

    def is_a_resubmission?
      submission.submitted_at_before_last_save &&
      submission.saved_change_to_submitted_at?
    end

    def grade_updated?
      submission.changed_in_state(:graded, :fields => [:score, :grade])
    end

    def graded_recently?
      submission.assignment_graded_in_the_last_hour?
    end

    def user_has_visibility?
      AssignmentStudentVisibility.where(assignment_id: submission.assignment_id, user_id: submission.user_id).any?
    end

    def user_active_or_invited?
      course.student_enrollments.where(user_id: submission.user_id).preload(:enrollment_state).to_a.any?{|e| e.active? || e.invited?}
    end
  end
end
