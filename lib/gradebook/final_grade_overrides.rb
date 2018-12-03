#
# Copyright (C) 2018 - present Instructure, Inc.
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

module Gradebook
  class FinalGradeOverrides
    def initialize(course, user)
      @course = course
      @user = user
    end

    def to_h
      scores = Score.
        where(enrollment_id: enrollment_ids_to_user_ids.keys).
        where.not(override_score: nil).
        to_a

      scores.each_with_object({}) do |score, map|
        user_id = enrollment_ids_to_user_ids[score.enrollment_id]
        score_map = map[user_id] ||= {}

        if score.course_score?
          score_map[:course_grade] = grade_info_from_score(score)
        else
          gp_map = score_map[:grading_period_grades] ||= {}
          gp_map[score.grading_period_id] = grade_info_from_score(score)
        end
      end
    end

    private

    def grade_info_from_score(score)
      {
        percentage: score.override_score
      }
    end

    def enrollment_ids_to_user_ids
      @enrollment_ids_to_user_ids ||= student_enrollments_scope.pluck(:id, :user_id).to_h
    end

    def student_enrollments_scope
      workflow_states = [:active, :inactive, :completed, :invited]
      student_enrollments = @course.enrollments.where(
        workflow_state: workflow_states,
        type: [:StudentEnrollment, :StudentViewEnrollment]
      )

      @course.apply_enrollment_visibility(student_enrollments, @user, nil, include: workflow_states)
    end
  end
end
