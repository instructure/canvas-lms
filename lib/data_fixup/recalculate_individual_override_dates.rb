# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

module DataFixup::RecalculateIndividualOverrideDates
  def self.run
    DatabaseServer.send_in_each_region(
      self,
      :run_for_region,
      { run_current_region_asynchronously: true }
    )
  end

  def self.run_for_region
    Shard.with_each_shard(Shard.in_current_region) do
      delay_if_production(
        n_strand: ["RecalculateIndividualOverrideDates.run_for_shard", Shard.current.database_server.id],
        priority: Delayed::LOWER_PRIORITY
      ).run_for_shard
    end
  end

  def self.run_for_shard
    Course.where(workflow_state: "available").find_in_batches do |courses|
      courses.each do |course|
        recalc_assignment_ids = Set.new
        assignment_ids_with_nonadhoc_override = course.assignments.active.joins(:assignment_overrides).merge(AssignmentOverride.active).where(assignment_overrides: { set_type: ["CourseSection", "Group"] }).distinct.except(:order).pluck(:id)

        assignment_ids_with_nonadhoc_override.each_slice(1_000) do |assignment_ids_slice|
          # for each assignment that has at least two overrides, one non-adhoc and one adhoc...
          Assignment.where(id: assignment_ids_slice).joins(:assignment_overrides).merge(AssignmentOverride.active).where(assignment_overrides: { set_type: "ADHOC" }).distinct.each do |assignment|
            # clear the assignment's 'availability' (due date + unlock date + lock date) cache key
            assignment.clear_cache_key(:availability)

            # clear the quiz's 'availability' (due date + unlock date + lock date) cache key if this is a quiz
            if assignment.quiz?
              assignment.quiz.clear_cache_key(:availability)
            end

            # add the assignment ID to the list of assignments we want to recompute due dates for
            recalc_assignment_ids.add(assignment.id)
          end
        end

        next if recalc_assignment_ids.empty?

        # recompute due dates for affected assignments. This ensures all submissions for affected assignments
        # will have a correct cached_due_date.
        DueDateCacher.recompute_course(
          course,
          assignments: recalc_assignment_ids.to_a,
          inst_jobs_opts: { priority: Delayed::LOWER_PRIORITY, strand: ["recalc_adhoc_override_dates", Shard.current.database_server.id] }
        )
      end
    end
  end
end
