# frozen_string_literal: true

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
      scores = Score
               .where(enrollment_id: enrollment_ids_to_user_ids.keys)
               .where.not(override_score: nil, custom_grade_status_id: nil)
               .to_a

      scores.each_with_object({}) do |score, map|
        user_id = enrollment_ids_to_user_ids[score.enrollment_id]
        score_map = map[user_id] ||= {}

        custom_grade_status_id = score.custom_grade_status_id

        if score.course_score?
          score_map[:course_grade] = grade_info_from_score(score)
          score_map[:course_grade][:custom_grade_status_id] = custom_grade_status_id
        else
          gp_map = score_map[:grading_period_grades] ||= {}
          gp_map[score.grading_period_id] = grade_info_from_score(score)
          gp_map[score.grading_period_id][:custom_grade_status_id] = custom_grade_status_id
        end
      end
    end

    def self.queue_bulk_update(course, current_user, override_scores, grading_period)
      progress = Progress.create!(context: course, tag: "override_grade_update")
      progress.process_job(self, :process_bulk_update, {}, course, current_user, override_scores, grading_period)
      progress
    end

    def self.process_bulk_update(progress, course, updating_user, override_data, grading_period)
      # A given student may have multiple enrollments; even if this instructor
      # can only see a subset of those enrollments, we need to update all
      # applicable enrollments for each student. At the same time, though, we
      # only want to record a single grade change event for each student.
      student_ids_updated = Set.new
      errors = []

      visible_students_scope = course.students_visible_to(updating_user, include: [:completed])

      custom_grade_statuses = course.custom_grade_statuses.to_a

      override_data.each_slice(1000) do |score_update_batch|
        student_ids = score_update_batch.pluck(:student_id)
        visible_students_in_batch = visible_students_scope.where(id: student_ids)

        enrollments_to_update = course.student_enrollments
                                      .preload(:scores)
                                      .where(user_id: visible_students_in_batch.select(:id))
                                      .group_by(&:user_id)

        score_update_batch.each do |score_update|
          student_id = score_update[:student_id].to_i
          if student_id <= 0
            errors << { student_id: score_update[:student_id], error: :invalid_student_id }
            next
          end

          next unless enrollments_to_update.key?(student_id)

          enrollments_to_update[student_id].each do |enrollment|
            if score_update.key?(:override_score)
              enrollment.update_override_score(
                override_score: score_update[:override_score],
                grading_period_id: grading_period&.id,
                updating_user:,
                record_grade_change: !student_ids_updated.include?(student_id)
              )
            end

            if score_update.key?(:override_status_id) && Account.site_admin.feature_enabled?(:custom_gradebook_statuses)
              custom_grade_status_id = score_update[:override_status_id]&.to_i
              custom_grade_status = custom_grade_statuses.find { |status| status.id == custom_grade_status_id } if custom_grade_status_id
              unless custom_grade_status_id.present? && custom_grade_status.nil?
                enrollment.update_override_status(
                  custom_grade_status:,
                  grading_period_id: grading_period&.id
                )
              end
            end

            student_ids_updated.add(student_id)
          rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid
            # Either we couldn't find a score for the requested grading period,
            # or there was a problem updating, maybe due to a malformed score
            errors << { student_id: score_update[:student_id], error: :failed_to_update }
          end
        end
      end

      progress&.set_results({ errors: })
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
      workflow_states = %i[active inactive completed invited]
      student_enrollments = @course.enrollments.where(
        workflow_state: workflow_states,
        type: [:StudentEnrollment, :StudentViewEnrollment]
      )

      @course.apply_enrollment_visibility(student_enrollments, @user, nil, include: workflow_states)
    end
  end
end
