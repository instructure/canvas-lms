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
class DataFixup::UpdatePointsBasedSchemeGradeChangeRecords
  def self.run
    GuardRail.activate(:secondary) do
      process_points_based_grading_standards
    end
  end

  def self.process_points_based_grading_standards
    GradingStandard.where(points_based: true).find_each(strategy: :id) do |grading_standard|
      process_grading_standard(grading_standard)
    end
  end

  def self.process_grading_standard(grading_standard)
    GuardRail.activate(:primary) do
      delay_if_production(
        priority: Delayed::LOWER_PRIORITY,
        n_strand: "Datafix:UpdatePointsBasedGradeChange:#{Shard.current.database_server.id}"
      ).run_for_assignments_using_standard_directly(grading_standard)
    end

    grading_standard.courses.find_each(strategy: :id) do |course|
      GuardRail.activate(:primary) do
        delay_if_production(
          priority: Delayed::LOWER_PRIORITY,
          n_strand: "Datafix:UpdatePointsBasedGradeChange:#{Shard.current.database_server.id}"
        ).run_for_course(course)
      end
    end
  end

  def self.run_for_assignments_using_standard_directly(grading_standard)
    GuardRail.activate(:secondary) do
      assignments_using_scheme_directly = grading_standard.assignments
      run_for_affected_assignments(assignments_using_scheme_directly)
    end
  end

  def self.run_for_course(course)
    GuardRail.activate(:secondary) do
      assignments_inheriting_scheme = course.assignments.where(grading_standard_id: nil, grading_type: ["letter_grade", "gpa_scale"])
      run_for_affected_assignments(assignments_inheriting_scheme)
    end
  end

  def self.run_for_affected_assignments(assignments)
    submissions_with_grades = Submission.where.not(grade: nil).where(assignment_id: assignments.select(:id))
    submissions_with_grades.preload(assignment: [:grading_standard, { context: :grading_standard }]).find_in_batches(batch_size: 1000) do |submissions_batch|
      change_records = Auditors::ActiveRecord::GradeChangeRecord
                       .where(submission: submissions_batch)
                       .order(submission_id: :asc, submission_version_number: :desc)
                       .distinct_on(:submission_id) # we only want the most recent change record for each submission
                       .index_by(&:submission_id)

      submissions_batch.each do |submission|
        change_record = change_records[submission.id]
        next unless change_record.present? && change_record.score_after == submission.score

        new_grade = submission.assignment.score_to_grade(submission.score, submission.grade)
        grade_has_changed = new_grade != change_record.grade_after
        if grade_has_changed
          GuardRail.activate(:primary) { change_record.update_columns(grade_after: new_grade) }
        end
      end
    end
  end
end
