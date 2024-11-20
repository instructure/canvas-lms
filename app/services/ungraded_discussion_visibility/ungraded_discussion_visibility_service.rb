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

module UngradedDiscussionVisibility
  class UngradedDiscussionVisibilityService
    extend VisibilityHelpers::Common
    class << self
      def discussion_topics_visible(course_ids: nil, user_ids: nil, discussion_topic_ids: nil)
        unless course_ids || user_ids || discussion_topic_ids
          raise ArgumentError, "at least one non nil course_id, user_id, or discussion_topic_id_params is required (for query performance reasons)"
        end

        course_ids = Array(course_ids) if course_ids
        user_ids = Array(user_ids) if user_ids
        discussion_topic_ids = Array(discussion_topic_ids) if discussion_topic_ids

        service_cache_fetch(service: name, course_ids:, user_ids:, additional_ids: discussion_topic_ids) do
          UngradedDiscussionVisibility::Repositories::UngradedDiscussionVisibleToStudentRepository.visibility_query(
            course_ids:, user_ids:, discussion_topic_ids:
          )
        end
      end
    end
  end
end
