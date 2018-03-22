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
#

# 1) For active courses and their active enrollments: force a
# recalculation of ALL THE THINGS to confirm all active courses have
# all the new data
#
# 2) For concluded courses and concluded enrollments in active
# courses: recalculate the grades but only store the points specifically and do not
# update scores

module DataFixup
  module PopulatePointsForAllScores
    def self.run
      Course.published.find_ids_in_ranges(batch_size: 100) do |min_id, max_id|
        send_later_if_production_enqueue_args(
          :run_for_course_range,
          {
            n_strand: ["DataFixup::PopulatePointsForAllScores", Shard.current.database_server.id],
            priority: Delayed::MAX_PRIORITY
          },
          min_id, max_id
        )
      end
    end

    def self.run_for_course_range(min_id, max_id)
      courses = Course.published.where(id: min_id..max_id)
      courses.each { |course| course.concluded? ? handle_concluded_course(course) : handle_active_course(course) }
    end

    def self.handle_active_course(course)
      current_student_ids = course.gradable_students.pluck(:id)
      GradeCalculator.recompute_final_score(current_student_ids, course)

      prior_student_ids = course.prior_students.pluck(:id)
      handle_concluded_students(course, prior_student_ids)
    end

    def self.handle_concluded_course(course)
      student_ids = course.all_students.pluck(:id)
      handle_concluded_students(course, student_ids)
    end

    def self.handle_concluded_students(course, student_ids)
      student_ids.each_slice(1000) do |user_ids_group|
        # This will add points to all Score objects. It might be inaccurate if the course changed in
        # some way after the enrollment concluded, but its the best we got and product can live with it.
        GradeCalculator.new(user_ids_group, course, only_update_points: true).compute_and_save_scores
      end
    end
  end
end
