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
      def wiki_pages_visible_to_students(course_ids: nil, user_ids: nil, wiki_page_ids: nil)
        unless course_ids || user_ids || wiki_page_ids
          raise ArgumentError, "at least one non nil course_id, user_id, or wiki_page_ids is required (for query performance reasons)"
        end

        course_ids = Array(course_ids) if course_ids
        user_ids = Array(user_ids) if user_ids
        wiki_page_ids = Array(wiki_page_ids) if wiki_page_ids

        service_cache_fetch(service: name, course_ids:, user_ids:, additional_ids: wiki_page_ids) do
          WikiPageVisibility::Repositories::WikiPageVisibleToStudentRepository.visibility_query(
            course_ids:, user_ids:, wiki_page_ids:
          )
        end
      end
    end
  end
end
