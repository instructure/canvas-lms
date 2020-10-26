# frozen_string_literal: true

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

module DataFixup::DeleteExtraPlaceholderSubmissions
  def self.run
    Course.find_ids_in_ranges do |min_id, max_id|
      send_later_if_production_enqueue_args(
        :run_for_course_range,
        {
          n_strand: ["DataFixup:DeleteExtraPlaceholderSubmissions", Shard.current.database_server.id],
          priority: Delayed::MAX_PRIORITY
        },
        min_id, max_id
      )
    end
  end

  def self.run_for_course_range(min_id, max_id)
    assignment_ids_by_course_id = {}
    Assignment.where(:context_type => "Course", :context_id => min_id..max_id).pluck(:context_id, :id).each do |c_id, a_id|
      (assignment_ids_by_course_id[c_id] ||= []) << a_id
    end
    return unless assignment_ids_by_course_id.present?

    Course.where(:id => assignment_ids_by_course_id.keys).to_a.each do |course|
      course_assignment_ids = assignment_ids_by_course_id[course.id]
      StudentEnrollment.where(course: course).in_batches do |relation|
        batch_student_ids = relation.pluck(:user_id)
        edd = EffectiveDueDates.for_course(course).filter_students_to(batch_student_ids)
        course_assignment_ids.each do |assignment_id|
          deletable_student_ids = batch_student_ids - edd.find_effective_due_dates_for_assignment(assignment_id).keys
          unless deletable_student_ids.blank?
            Submission.active.
              where(assignment_id: assignment_id, user_id: deletable_student_ids).
              update_all(workflow_state: :deleted)
          end
        end
      end
    end
  end
end
