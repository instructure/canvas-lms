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
class DataFixup::RegradeVersionsForPointsBasedSchemeAssignments
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
        n_strand: "Datafix:RegradePointsBased:#{Shard.current.database_server.id}"
      ).run_for_assignments_using_standard_directly(grading_standard)
    end

    grading_standard.courses.find_each(strategy: :id) do |course|
      GuardRail.activate(:primary) do
        delay_if_production(
          priority: Delayed::LOWER_PRIORITY,
          n_strand: "Datafix:RegradePointsBased:#{Shard.current.database_server.id}"
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
    current_versions_for_submissions = Version
                                       .where(versionable: Submission.where(assignment: assignments))
                                       .order(versionable_id: :asc, number: :desc)
                                       .distinct_on(:versionable_id) # we only want the _most recent_ version associated with each submission
    current_versions_for_submissions.preload(versionable: { assignment: [:grading_standard, { context: :grading_standard }] }).find_each do |version|
      model = version.model
      next unless model.grade.present?

      new_grade = version.versionable.assignment.score_to_grade(model.score, model.grade)
      grade_has_changed = new_grade != model.grade || new_grade != model.published_grade
      next unless grade_has_changed

      model.grade = new_grade
      model.published_grade = new_grade
      yaml = model.attributes.to_yaml
      # We can't use the same upsert_all approach that we used in DataFixup::RegradePointsBasedSchemeAssignments
      # because the versions table is partitioned.
      GuardRail.activate(:primary) { version.update_columns(yaml:) }
    end
  end
end
