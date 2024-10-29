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

module AssignmentVisibility
  class AssignmentVisibilityService
    extend VisibilityHelpers::Common
    class << self
      def visible_assignment_ids_in_course_by_user(user_ids:, course_ids:, use_global_id: false)
        raise ArgumentError, "course_ids cannot be nil" if course_ids.nil?
        raise ArgumentError, "course_ids must be an array" unless course_ids.is_a?(Array)
        raise ArgumentError, "user_ids cannot be nil" if user_ids.nil?
        raise ArgumentError, "user_ids must be an array" unless user_ids.is_a?(Array)

        vis_hash = {}
        assignments_visible_to_students(user_ids:, course_ids:).each do |assignment_visible_to_student|
          user_id = assignment_visible_to_student.user_id
          user_id = Shard.global_id_for(user_id) if use_global_id
          vis_hash[user_id] ||= []
          vis_hash[user_id] << assignment_visible_to_student.assignment_id
        end
        # if users have no visibilities add their keys to the hash with an empty array
        vis_hash.reverse_merge!(user_ids.index_with { [] })
      end

      def users_with_visibility_by_assignment(course_id:, assignment_ids:)
        raise ArgumentError, "course_id cannot be nil" if course_id.nil?
        raise ArgumentError, "course_id must not be an array" if course_id.is_a?(Array)
        raise ArgumentError, "assignment_ids cannot be nil" if assignment_ids.nil?
        raise ArgumentError, "assignment_ids must be an array" unless assignment_ids.is_a?(Array)

        vis_hash = {}
        assignments_visible_to_students(course_ids: course_id, assignment_ids:)
          .each do |assignment_visible_to_student|
          vis_hash[assignment_visible_to_student.assignment_id] ||= []
          vis_hash[assignment_visible_to_student.assignment_id] << assignment_visible_to_student.user_id
        end

        # if assignment/quiz has no users with visibility, add their keys to the hash with an empty array
        vis_hash.reverse_merge!(assignment_ids.index_with { [] })
      end

      def users_with_visibility_by_assignment_for_users(course_id:, assignment_ids:, user_ids:)
        raise ArgumentError, "course_id cannot be nil" if course_id.nil?
        raise ArgumentError, "course_id must not be an array" if course_id.is_a?(Array)
        raise ArgumentError, "assignment_ids cannot be nil" if assignment_ids.nil?
        raise ArgumentError, "assignment_ids must be an array" unless assignment_ids.is_a?(Array)
        raise ArgumentError, "user_ids cannot be nil" if user_ids.nil?
        raise ArgumentError, "user_ids must be an array" unless user_ids.is_a?(Array)

        vis_hash = {}
        assignments_visible_to_students(course_ids: course_id, assignment_ids:, user_ids:)
          .each do |assignment_visible_to_student|
          vis_hash[assignment_visible_to_student.assignment_id] ||= []
          vis_hash[assignment_visible_to_student.assignment_id] << assignment_visible_to_student.user_id
        end

        # if assignment/quiz has no users with visibility, add their keys to the hash with an empty array
        vis_hash.reverse_merge!(assignment_ids.index_with { [] })
      end

      def assignments_visible_to_student(course_id:, user_id:)
        raise ArgumentError, "course_id cannot be nil" if course_id.nil?
        raise ArgumentError, "course_id must not be an array" if course_id.is_a?(Array)
        raise ArgumentError, "user_id cannot be nil" if user_id.nil?
        raise ArgumentError, "user_id must not be an array" if user_id.is_a?(Array)

        assignments_visible_to_students(course_ids: course_id, user_ids: user_id)
      end

      def assignments_visible_to_students_in_courses(course_ids:, user_ids:)
        raise ArgumentError, "course_ids cannot be nil" if course_ids.nil?
        raise ArgumentError, "course_ids must be an array" unless course_ids.is_a?(Array)
        raise ArgumentError, "user_ids cannot be nil" if user_ids.nil?
        raise ArgumentError, "user_ids must be an array" unless user_ids.is_a?(Array)

        assignments_visible_to_students(course_ids:, user_ids:)
      end

      def assignment_visible_to_student(assignment_id:, user_id:)
        raise ArgumentError, "assignment_id cannot be nil" if assignment_id.nil?
        raise ArgumentError, "assignment_id must not be an array" if assignment_id.is_a?(Array)
        raise ArgumentError, "user_id cannot be nil" if user_id.nil?
        raise ArgumentError, "user_id must not be an array" if user_id.is_a?(Array)

        assignments_visible_to_students(assignment_ids: assignment_id, user_ids: user_id)
      end

      def assignment_visible_to_students(assignment_id:, user_ids:)
        raise ArgumentError, "assignment_id cannot be nil" if assignment_id.nil?
        raise ArgumentError, "assignment_id must not be an array" if assignment_id.is_a?(Array)
        raise ArgumentError, "user_ids cannot be nil" if user_ids.nil?
        raise ArgumentError, "user_ids must be an array" unless user_ids.is_a?(Array)

        assignments_visible_to_students(assignment_ids: assignment_id, user_ids:)
      end

      def assignments_visible_to_student_by_assignment(assignment_ids:, user_id:)
        raise ArgumentError, "assignment_ids cannot be nil" if assignment_ids.nil?
        raise ArgumentError, "assignment_ids must be an array" unless assignment_ids.is_a?(Array)
        raise ArgumentError, "user_id cannot be nil" if user_id.nil?
        raise ArgumentError, "user_ids must not be an array" if user_id.is_a?(Array)

        assignments_visible_to_students(assignment_ids:, user_ids: user_id)
      end

      def assignment_visible_to_students_in_course(assignment_ids:, user_ids:, course_ids:)
        raise ArgumentError, "course_ids cannot be nil" if course_ids.nil?
        raise ArgumentError, "course_ids must be an array" unless course_ids.is_a?(Array)
        raise ArgumentError, "assignment_ids cannot be nil" if assignment_ids.nil?
        raise ArgumentError, "assignment_ids must be an array" unless assignment_ids.is_a?(Array)
        raise ArgumentError, "user_ids cannot be nil" if user_ids.nil?
        raise ArgumentError, "user_ids must be an array" unless user_ids.is_a?(Array)

        assignments_visible_to_students(course_ids:, assignment_ids:, user_ids:)
      end

      def assignment_visible_in_course(assignment_id:, course_id:)
        raise ArgumentError, "course_id cannot be nil" if course_id.nil?
        raise ArgumentError, "course_id must not be an array" if course_id.is_a?(Array)
        raise ArgumentError, "assignment_id cannot be nil" if assignment_id.nil?
        raise ArgumentError, "assignment_id must not be an array" if assignment_id.is_a?(Array)

        assignments_visible_to_students(course_ids: course_id, assignment_ids: assignment_id)
      end

      def assignments_visible_in_course(assignment_ids:, course_id:)
        raise ArgumentError, "course_id cannot be nil" if course_id.nil?
        raise ArgumentError, "course_id must not be an array" if course_id.is_a?(Array)
        raise ArgumentError, "assignment_ids cannot be nil" if assignment_ids.nil?
        raise ArgumentError, "assignment_ids must be an array" unless assignment_ids.is_a?(Array)

        assignments_visible_to_students(course_ids: course_id, assignment_ids:)
      end

      # TODO: better name for this method, or a better location?
      def assignments_with_user_visibilities(course, assignments)
        visible_to_everyone, only_visible_to_overrides = assignments.partition(&:visible_to_everyone)
        assignment_visibilities = {}

        if only_visible_to_overrides.any?
          assignment_visibilities.merge!(users_with_visibility_by_assignment(
                                           course_id: course.id,
                                           assignment_ids: only_visible_to_overrides.map(&:id)
                                         ))
        end

        if visible_to_everyone.any?
          # if an assignment is visible to everyone, we do not care about the contents
          # of its assignment_visibilities. instead of setting this to an array of every
          # student's ID, we set it to an empty array to save time when calling to_json
          assignment_visibilities.merge!(visible_to_everyone.map(&:id).index_with { [] })
        end

        assignment_visibilities
      end

      private

      def assignments_visible_to_students(course_ids: nil, user_ids: nil, assignment_ids: nil)
        service_cache_fetch(service: name,

                            course_ids:,
                            user_ids:,
                            additional_ids: assignment_ids) do
          # Must have a course_id or assignment_id for performance of the all_tags section of the query
          # General query performance requires at least one non-nil course_id, assignment_id, or user_id
          if course_ids.nil? && assignment_ids.nil?
            raise ArgumentError, "at least one non nil course_id or assignment_id is required (for query performance reasons)"
          end

          AssignmentVisibility::Repositories::AssignmentVisibleToStudentRepository.visibility_query(
            course_ids:, user_ids:, assignment_ids:
          )
        end
      end
    end
  end
end
