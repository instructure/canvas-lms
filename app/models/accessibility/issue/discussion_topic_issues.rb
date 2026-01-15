# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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
module Accessibility
  class Issue
    module DiscussionTopicIssues
      def generate_discussion_topic_resources(skip_scan: false)
        discussion_topics = context.discussion_topics
        return discussion_topics.map { |discussion_topic| discussion_topic_attributes(discussion_topic) } if skip_scan

        discussion_topics.each_with_object({}) do |discussion_topic, issues|
          result = check_content_accessibility(discussion_topic.message.to_s)
          issues[discussion_topic.id] = result.merge(discussion_topic_attributes(discussion_topic))
        end
      end

      private

      def discussion_topic_attributes(discussion_topic)
        {
          title: discussion_topic.title,
          published: discussion_topic.published?,
          updated_at: discussion_topic.updated_at.iso8601 || ""
        }.merge(resource_urls(discussion_topic))
      end
    end
  end
end
