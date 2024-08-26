# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

class Loaders::AssessmentRequestLoader < GraphQL::Batch::Loader
  def initialize(current_user:)
    super()
    @current_user = current_user
  end

  # This is somewhat complicated to remove a plethora of N+1s
  def perform(input_assignments)
    valid_students_by_course_id = {}

    assignments_by_shard = input_assignments.group_by(&:shard)

    assignments_by_shard.each do |shard, assignments|
      assignments.each_slice(1000) do |assignment_slice|
        all_reviews = @current_user.assigned_submission_assessments.shard(shard).for_assignment(assignment_slice)
        reviews_by_assignment = all_reviews.group_by { |r| r.submission.assignment_id }

        unless reviews_by_assignment.empty?
          ActiveRecord::Associations.preload(assignment_slice, :context)
          assignment_slice.map(&:course).uniq.each do |course|
            next if valid_students_by_course_id[course.global_id]

            user_ids = all_reviews.map(&:user_id).uniq
            valid_students_by_course_id[course.global_id] = course.participating_students.where(id: user_ids).pluck(:id)
          end
        end

        assignment_slice.each do |assignment|
          reviews = reviews_by_assignment[assignment.id]
          if reviews
            valid_student_ids = valid_students_by_course_id[assignment.course.global_id]
            fulfill(assignment, reviews.select { |r| valid_student_ids.include?(r.user_id) })
          else
            fulfill(assignment, [])
          end
        end
      end
    end
  end
end
