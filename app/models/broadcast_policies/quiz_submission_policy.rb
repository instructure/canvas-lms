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
  class QuizSubmissionPolicy
    attr_reader :quiz_submission

    def initialize(quiz_submission)
      @quiz_submission = quiz_submission
    end

    def should_dispatch_submission_graded?
      quiz_is_accepting_messages_for_student? &&
      (quiz_submission.changed_state_to(:complete) || manually_graded) &&
      user_is_actively_enrolled?
    end

    def should_dispatch_submission_grade_changed?
      quiz_is_accepting_messages_for_student? &&
      quiz_submission.submission.try(:graded_at) &&
      quiz_submission.changed_in_state(:complete, :fields => [:score]) &&
      user_is_actively_enrolled? &&
      user_has_visibility?
    end

    def should_dispatch_submission_needs_grading?
      !quiz.survey? &&
      quiz_is_accepting_messages_for_admin? &&
      quiz_submission.changed_state_to(:pending_review) &&
      user_has_visibility?
    end

    private
    def quiz
      quiz_submission.quiz
    end

    def quiz_is_accepting_messages_for_student?
      quiz_submission &&
      quiz.assignment &&
      !quiz.muted? &&
      quiz.context.available? &&
      !quiz.deleted?
    end

    def quiz_is_accepting_messages_for_admin?
      quiz_submission &&
        quiz.assignment &&
        quiz.context.available? &&
        !quiz.deleted?
    end

    def manually_graded
      quiz_submission.changed_in_state(:pending_review, :fields => [:fudge_points])
    end

    def user_has_visibility?
      return false if quiz_submission.user_id.nil?
      Quizzes::QuizStudentVisibility.where(quiz_id: quiz.id, user_id: quiz_submission.user_id).any?
    end

    def user_is_actively_enrolled?
      return false if quiz_submission.user.nil?
      quiz_submission.user.not_removed_enrollments.where(course_id: quiz.context_id).any?
    end
  end
end
