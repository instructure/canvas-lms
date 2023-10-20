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

module DataFixup::RecalculateSectionOverrideDates
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
        n_strand: ["RecalculateSectionOverrideDates.run_for_shard", Shard.current.database_server.id],
        priority: Delayed::LOWER_PRIORITY
      ).run_for_shard
    end
  end

  def self.run_for_shard
    Course.find_ids_in_ranges do |min_id, max_id|
      # for each active course...
      courses = Course.where(id: min_id..max_id, workflow_state: "available")
      courses.each do |course|
        # find assignments (in batches of 100) that have:
        # A. at least one section override, and
        # B. an "everyone" due date, or another override
        Assignment.where(context: course).find_ids_in_batches(batch_size: 100) do |ids|
          affected_assignments = Assignment
                                 .active
                                 .where(id: ids)
                                 .joins(:assignment_overrides)
                                 .merge(AssignmentOverride.active)
                                 .group("assignments.id", "assignments.only_visible_to_overrides")
                                 .having(
                                   <<~SQL.squish
                                     /* filter for assignments where there's at least one section override */
                                     COUNT(assignments.id) FILTER (WHERE assignment_overrides.set_type = 'CourseSection') > 0
                                     AND
                                     /* and there's one override and one 'everyone' date, OR at least two overrides */
                                     (
                                       assignments.only_visible_to_overrides IS FALSE
                                       OR
                                       COUNT(assignments.id) >= 2
                                     )
                                   SQL
                                 )
                                 .to_a

          # ...and clear their availability dates cache
          affected_assignments.each do |assignment|
            assignment.clear_cache_key(:availability)

            if assignment.quiz?
              assignment.quiz.clear_cache_key(:availability)
            end
          end

          next if affected_assignments.empty?

          # ...and recompute the cached_due_date on their submissions.
          SubmissionLifecycleManager.recompute_course(
            course,
            assignments: affected_assignments.map(&:id),
            inst_jobs_opts: { priority: Delayed::LOWER_PRIORITY, strand: ["recalc_section_override_dates", Shard.current.database_server.id] }
          )
        end
      end
    end
  end
end
