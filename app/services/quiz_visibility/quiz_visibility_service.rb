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

module QuizVisibility
  class QuizVisibilityService
    extend VisibilityHelpers::Common
    class << self
      def visible_quiz_ids_in_course_by_user(user_ids:, course_ids:, use_global_id: false)
        vis_hash = quizzes_visible_to_students(user_ids:, course_ids:)
                   .group_by(&:user_id)
                   .transform_values { |a| a.map(&:quiz_id) }

        vis_hash.transform_keys! { |k| Shard.global_id_for(k) } if use_global_id

        # if users have no visibilities add their keys to the hash with an empty array
        vis_hash.reverse_merge!(user_ids.index_with { [] })
      end

      def quizzes_visible_to_students(course_ids: nil, user_ids: nil, quiz_ids: nil)
        unless course_ids || user_ids || quiz_ids
          raise ArgumentError, "at least one non nil course_id, user_id, or quiz_id is required (for query performance reasons)"
        end

        course_ids = Array(course_ids) if course_ids
        user_ids = Array(user_ids) if user_ids
        quiz_ids = Array(quiz_ids) if quiz_ids

        service_cache_fetch(service: name, course_ids:, user_ids:, additional_ids: quiz_ids) do
          QuizVisibility::Repositories::QuizVisibleToStudentRepository.visibility_query(
            course_ids:, user_ids:, quiz_ids:
          )
        end
      end
    end
  end
end
