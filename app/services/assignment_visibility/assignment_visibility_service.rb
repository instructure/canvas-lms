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
        vis_hash = assignments_visible_to_students(user_ids:, course_ids:)
                   .group_by(&:user_id)
                   .transform_values { |a| a.map(&:assignment_id) }
        vis_hash.transform_keys! { |k| Shard.global_id_for(k) } if use_global_id

        # if users have no visibilities add their keys to the hash with an empty array
        vis_hash.reverse_merge!(user_ids.index_with { [] })
      end

      def users_with_visibility_by_assignment(course_id:, assignment_ids:, user_ids: nil)
        vis_hash = assignments_visible_to_students(course_ids: course_id, assignment_ids:, user_ids:)
                   .group_by(&:assignment_id)
                   .transform_values { |a| a.map(&:user_id) }

        # if assignment/quiz has no users with visibility, add their keys to the hash with an empty array
        vis_hash.reverse_merge!(assignment_ids.index_with { [] })
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

      def assignments_visible_to_students(course_ids: nil, user_ids: nil, assignment_ids: nil, include_concluded: true)
        # Must have a course_id or assignment_id for performance of the all_tags section of the query
        # General query performance requires at least one non-nil course_id, assignment_id, or user_id
        unless course_ids || assignment_ids
          raise ArgumentError, "at least one non nil course_id or assignment_id is required (for query performance reasons)"
        end

        course_ids = Array(course_ids) if course_ids
        user_ids = Array(user_ids) if user_ids
        assignment_ids = Array(assignment_ids) if assignment_ids

        service_cache_fetch(service: name, course_ids:, user_ids:, additional_ids: assignment_ids, include_concluded:) do
          AssignmentVisibility::Repositories::AssignmentVisibleToStudentRepository.visibility_query(
            course_ids:, user_ids:, assignment_ids:, include_concluded:
          )
        end
      end

      def invalidate_cache(course_ids: nil, user_ids: nil, assignment_ids: nil, include_concluded: true)
        unless course_ids || assignment_ids
          raise ArgumentError, "at least one non nil course_id or assignment_id is required (for query performance reasons)"
        end

        course_ids = Array(course_ids) if course_ids
        user_ids = Array(user_ids) if user_ids
        assignment_ids = Array(assignment_ids) if assignment_ids

        key = service_cache_key(service: name, course_ids:, user_ids:, additional_ids: assignment_ids, include_concluded:)

        Rails.cache.delete(key)
      end
    end
  end
end
