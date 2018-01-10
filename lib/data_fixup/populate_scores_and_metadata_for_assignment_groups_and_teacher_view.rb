#
# Copyright (C) 2017 - present Instructure, Inc.
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
# all the new datums
#
# 2) For concluded courses and concluded enrollments in active
# courses: if the unposted scores are nil, copy the posted scores
# over, if the unposted scores are filled in, leave them as is. For
# assignment groups and metadata, recalculate the grades but only
# store the new data specifically and do not update scores
module DataFixup::PopulateScoresAndMetadataForAssignmentGroupsAndTeacherView
  def self.run
    Course.published.find_ids_in_ranges do |min_id, max_id|
      send_later_if_production_enqueue_args(
        :run_for_course_range,
        {
          n_strand: ["DataFixup::PopulateScoresAndMetadataForAssignmentGroupsAndTeacherView", Shard.current.database_server.id],
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
      # For concluded enrollments before we started calculating
      # unposted scores, just copy the posted scores over as the
      # course might have changed around the concluded enrollments. If
      # a concluded enrollment already has the unposted scores, we'll
      # want to use those
      score_ids = Score.joins(:enrollment).
        where(enrollments: { type: ['StudentEnrollment', 'StudentViewEnrollment'],
                             course_id: course.id, user_id: user_ids_group },
              unposted_current_score: nil, unposted_final_score: nil).pluck(:id)
      score_ids.each_slice(1000) do |ids|
        Score.where(id: ids).update_all("unposted_current_score = current_score, unposted_final_score = final_score")
      end


      # This will add/update the assignment group scores and the
      # ScoreMetadata. It might be inaccurate if the course changed in
      # some way after the enrollment concluded, but its the best we
      # got and product can live with it.
      GradeCalculator.new(user_ids_group, course, only_update_course_gp_metadata: true).compute_and_save_scores
    end
  end
end
