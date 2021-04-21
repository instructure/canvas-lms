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
#

module Types
  class DiscussionType < ApplicationObjectType
    graphql_name "Discussion"

    implements GraphQL::Types::Relay::Node
    implements Interfaces::TimestampInterface
    implements Interfaces::ModuleItemInterface
    implements Interfaces::LegacyIDInterface

    global_id_field :id
    field :title, String, null: true
    field :delayed_post_at, Types::DateTimeType, null: true
    field :lock_at, Types::DateTimeType, null: true
    field :last_reply_at, Types::DateTimeType, null: true
    field :posted_at, Types::DateTimeType, null: true
    field :podcast_has_student_posts, Boolean, null: true
    field :discussion_type, String, null: true
    field :position, Int, null: true
    field :allow_rating, Boolean, null: true
    field :only_graders_can_rate, Boolean, null: true
    field :sort_by_rating, Boolean, null: true
    field :is_section_specific, Boolean, null: true
    field :require_initial_post, Boolean, null: true

    field :published, Boolean, null: false
    def published
      object.published?
    end

    field :assignment, Types::AssignmentType, null: true
    def assignment
      load_association(:assignment)
    end

    field :root_topic, Types::DiscussionType, null: true
    def root_topic
      load_association(:root_topic)
    end

    field :discussion_entries_connection, Types::DiscussionEntryType.connection_type, null: true
    def discussion_entries_connection
      load_association(:discussion_entries)
    end

    field :root_discussion_entries_connection, Types::DiscussionEntryType.connection_type, null: true
    def root_discussion_entries_connection
      load_association(:root_discussion_entries)
    end

    field :subscribed, Boolean, null: false
    def subscribed
      load_association(:discussion_topic_participants).then do
        object.subscribed?(current_user)
      end
    end

    field :author, Types::UserType, null: false
    def author
      load_association(:user)
    end

    field :editor, Types::UserType, null: true
    def editor
      load_association(:editor)
    end
  end
end
