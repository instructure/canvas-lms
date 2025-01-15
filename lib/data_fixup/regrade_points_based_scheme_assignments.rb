# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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
class DataFixup::RegradePointsBasedSchemeAssignments
  def self.run
    current_time = Time.zone.now
    GuardRail.activate(:secondary) do
      process_points_based_grading_standards(current_time)
    end
  end

  def self.process_points_based_grading_standards(current_time)
    GradingStandard.where(points_based: true).find_each do |grading_standard|
      process_grading_standard(grading_standard, current_time)
    end
  end

  def self.process_grading_standard(grading_standard, current_time)
    assignments_using_scheme_directly = grading_standard.assignments
    run_for_affected_assignments(assignments_using_scheme_directly, current_time)

    affected_courses = grading_standard.courses
    affected_courses.find_each do |course|
      assignments_inheriting_scheme = course.assignments.where(grading_standard_id: nil, grading_type: ["letter_grade", "gpa_scale"])
      run_for_affected_assignments(assignments_inheriting_scheme, current_time)
    end
  end

  def self.run_for_affected_assignments(assignments, current_time)
    submissions_with_grades = Submission.where.not(grade: nil).where(assignment_id: assignments.select(:id))
    submissions_with_grades.preload(assignment: [:grading_standard, { context: :grading_standard }]).find_in_batches(batch_size: 1000) do |submissions_batch|
      batched_updates = submissions_batch.each_with_object([]) do |submission, acc|
        new_grade = submission.assignment.score_to_grade(submission.score, submission.grade)
        grade_has_changed = new_grade != submission.grade || new_grade != submission.published_grade
        if grade_has_changed
          acc << submission.attributes.merge("grade" => new_grade, "published_grade" => new_grade, "updated_at" => current_time)
        end
      end

      GuardRail.activate(:primary) do
        Submission.upsert_all(
          batched_updates,
          unique_by: :id,
          update_only: %i[grade published_grade updated_at],
          record_timestamps: false,
          returning: false
        )
      end
    end
  end
end
