# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

class CoursePacing::RemoveOverridesService
  def self.call(course_id)
    course = Course.find_by(id: course_id)
    return unless course

    course.shard.activate do
      overrides_removed = 0
      assignments_to_refresh = Set.new

      AssignmentOverride.joins(:assignment)
                        .where(assignments: { context: course })
                        .where(title: "Course Pacing", set_type: "ADHOC")
                        .preload(:assignment)
                        .find_each do |override|
                          assignments_to_refresh << override.assignment
                          override.destroy
                          overrides_removed += 1
      end

      if overrides_removed > 0
        Assignment.clear_cache_keys(assignments_to_refresh, :availability)
        SubmissionLifecycleManager.recompute_course(course, assignments: assignments_to_refresh, update_grades: true)
        InstStatsd::Statsd.count("course_pacing.overrides_removed_on_disable", overrides_removed)
      end

      overrides_removed
    end
  end
end
