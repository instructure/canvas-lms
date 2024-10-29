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

module WikiPageVisibility
  class WikiPageVisibilityService
    extend VisibilityHelpers::Common
    class << self
      def wiki_pages_visible_to_student(course_id:, user_id:)
        raise ArgumentError, "course_id cannot be nil" if course_id.nil?
        raise ArgumentError, "course_id must not be an array" if course_id.is_a?(Array)
        raise ArgumentError, "user_id cannot be nil" if user_id.nil?
        raise ArgumentError, "user_id must not be an array" if user_id.is_a?(Array)

        wiki_pages_visible_to_students(course_ids: course_id, user_ids: user_id)
      end

      def wiki_pages_visible_to_students_in_courses(course_ids:, user_ids:)
        raise ArgumentError, "course_ids cannot be nil" if course_ids.nil?
        raise ArgumentError, "course_ids must be an array" unless course_ids.is_a?(Array)
        raise ArgumentError, "user_ids cannot be nil" if user_ids.nil?
        raise ArgumentError, "user_ids must be an array" unless user_ids.is_a?(Array)

        wiki_pages_visible_to_students(course_ids:, user_ids:)
      end

      def wiki_pages_visible_to_student_in_courses(user_id:, course_ids:)
        raise ArgumentError, "course_ids cannot be nil" if course_ids.nil?
        raise ArgumentError, "course_ids must be an array" unless course_ids.is_a?(Array)
        raise ArgumentError, "user_id cannot be nil" if user_id.nil?
        raise ArgumentError, "user_id must not be an array" if user_id.is_a?(Array)

        wiki_pages_visible_to_students(course_ids:, user_ids: user_id)
      end

      def wiki_page_visible_to_student(wiki_page_id:, user_id:)
        raise ArgumentError, "wiki_page_id cannot be nil" if wiki_page_id.nil?
        raise ArgumentError, "wiki_page_id must not be an array" if wiki_page_id.is_a?(Array)
        raise ArgumentError, "user_id cannot be nil" if user_id.nil?
        raise ArgumentError, "user_id must not be an array" if user_id.is_a?(Array)

        wiki_pages_visible_to_students(wiki_page_ids: wiki_page_id, user_ids: user_id)
      end

      def wiki_page_visible_to_students(wiki_page_id:, user_ids:)
        raise ArgumentError, "wiki_page_id cannot be nil" if wiki_page_id.nil?
        raise ArgumentError, "wiki_page_id must not be an array" if wiki_page_id.is_a?(Array)
        raise ArgumentError, "user_ids cannot be nil" if user_ids.nil?
        raise ArgumentError, "user_ids must be an array" unless user_ids.is_a?(Array)

        wiki_pages_visible_to_students(wiki_page_ids: wiki_page_id, user_ids:)
      end

      def wiki_page_visible_to_students_in_course(wiki_page_id:, user_ids:, course_id:)
        raise ArgumentError, "course_id cannot be nil" if course_id.nil?
        raise ArgumentError, "course_id must not be an array" if course_id.is_a?(Array)
        raise ArgumentError, "wiki_page_id cannot be nil" if wiki_page_id.nil?
        raise ArgumentError, "wiki_page_id must not be an array" if wiki_page_id.is_a?(Array)
        raise ArgumentError, "user_ids cannot be nil" if user_ids.nil?
        raise ArgumentError, "user_ids must be an array" unless user_ids.is_a?(Array)

        wiki_pages_visible_to_students(course_ids: course_id, wiki_page_ids: wiki_page_id, user_ids:)
      end

      private

      def wiki_pages_visible_to_students(course_ids: nil, user_ids: nil, wiki_page_ids: nil)
        if course_ids.nil? && user_ids.nil? && wiki_page_ids.nil?
          raise ArgumentError, "at least one non nil course_id, user_id, or wiki_page_ids is required (for query performance reasons)"
        end

        service_cache_fetch(service: name,
                            course_ids:,
                            user_ids:,
                            additional_ids: wiki_page_ids) do
          WikiPageVisibility::Repositories::WikiPageVisibleToStudentRepository.visibility_query(
            course_ids:, user_ids:, wiki_page_ids:
          )
        end
      end
    end
  end
end
