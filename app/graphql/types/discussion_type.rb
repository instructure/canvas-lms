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

class DiscussionFilterType < Types::BaseEnum
  graphql_name 'DiscussionFilterType'
  description 'Search types that can be associated with discussions'
  value 'all'
  value 'unread'
  value 'deleted'
end

class DiscussionSortOrderType < Types::BaseEnum
  graphql_name 'DiscussionSortOrderType'
  value 'asc', value: :asc
  value 'desc', value: :desc
end

module Types
  class DiscussionType < ApplicationObjectType
    graphql_name "Discussion"

    implements GraphQL::Types::Relay::Node
    implements Interfaces::TimestampInterface
    implements Interfaces::ModuleItemInterface
    implements Interfaces::LegacyIDInterface

    global_id_field :id
    field :title, String, null: true
    field :message, String, null: true
    field :context_id, ID, null: false
    field :context_type, String, null: false
    field :delayed_post_at, Types::DateTimeType, null: true
    field :lock_at, Types::DateTimeType, null: true
    field :locked, Boolean, null: false
    field :last_reply_at, Types::DateTimeType, null: true
    field :posted_at, Types::DateTimeType, null: true
    field :podcast_has_student_posts, Boolean, null: true
    field :discussion_type, String, null: true
    field :position, Int, null: true
    field :allow_rating, Boolean, null: true
    field :only_graders_can_rate, Boolean, null: true
    field :sort_by_rating, Boolean, null: true
    field :is_announcement, Boolean, null: false
    field :is_section_specific, Boolean, null: true
    field :require_initial_post, Boolean, null: true

    field :initial_post_required_for_current_user, Boolean, null: false
    def initial_post_required_for_current_user
      object.initial_post_required?(current_user, session)
    end

    field :published, Boolean, null: false
    def published
      object.published?
    end

    field :assignment, Types::AssignmentType, null: true
    def assignment
      load_association(:assignment)
    end

    field :attachment, Types::FileType, null: true
    def attachment
      load_association(:attachment)
    end

    field :root_topic, Types::DiscussionType, null: true
    def root_topic
      load_association(:root_topic)
    end

    field :discussion_entries_connection, Types::DiscussionEntryType.connection_type, null: true do
      argument :search_term, String, required: false
      argument :filter, DiscussionFilterType, required: false
      argument :sort_order, DiscussionSortOrderType, required: false
      argument :root_entries, Boolean, required: false
    end
    def discussion_entries_connection(**args)
      get_entries(args)
    end

    field :entry_counts, Types::DiscussionEntryCountsType, null: true
    def entry_counts
      Loaders::DiscussionEntryCountsLoader.for(current_user: current_user).load(object)
    end

    field :subscribed, Boolean, null: false
    def subscribed
      load_association(:discussion_topic_participants).then do
        object.subscribed?(current_user)
      end
    end

    field :group_set, Types::GroupSetType, null: true
    def group_set
      load_association(:group_category)
    end

    field :child_topics, [Types::DiscussionType], null: true
    def child_topics
      load_association(:child_topics)
    end

    field :context_name, String, null: true
    def context_name
      load_association(:context).then do |context|
        context&.name
      end
    end

    field :author, Types::UserType, null: true
    def author
      load_association(:user)
    end

    field :editor, Types::UserType, null: true
    def editor
      load_association(:editor)
    end

    field :permissions, Types::DiscussionPermissionsType, null: true
    def permissions
      load_association(:context).then do
        {
          loader: Loaders::PermissionsLoader.for(object, current_user: current_user, session: session),
          discussion_topic: object
        }
      end
    end

    field :course_sections, [Types::SectionType], null: false
    def course_sections
      load_association(:course_sections)
    end

    field :can_unpublish, Boolean, null: false
    def can_unpublish
      object.can_unpublish?
    end

    field :entries_total_pages, Integer, null: true do
      argument :per_page, Integer, required: true
      argument :search_term, String, required: false
      argument :filter, DiscussionFilterType, required: false
      argument :sort_order, DiscussionSortOrderType, required: false
      argument :root_entries, Boolean, required: false
    end
    def entries_total_pages(**args)
      get_entry_page_count(args)
    end

    field :root_entries_total_pages, Integer, null: true do
      argument :per_page, Integer, required: true
      argument :search_term, String, required: false
      argument :filter, DiscussionFilterType, required: false
      argument :sort_order, DiscussionSortOrderType, required: false
    end
    def root_entries_total_pages(**args)
      args[:root_entries] = true
      get_entry_page_count(args)
    end

    def get_entry_page_count(**args)
      per_page = args.delete(:per_page)
      get_entries(args).then do |entries|
        (entries.count.to_f / per_page).ceil
      end
    end

    field :search_entry_count, Integer, null: true do
      argument :search_term, String, required: false
      argument :filter, DiscussionFilterType, required: false
    end
    def search_entry_count(**args)
      get_entries(args).then do |entries|
        entries.count
      end
    end

    field :mentionable_users_connection, Types::MessageableUserType.connection_type, null: true do
      argument :search_term, String, required: false
    end
    def mentionable_users_connection(search_term: nil)
      Loaders::MentionableUserLoader.for(
        current_user: current_user,
        search_term: search_term
      ).load(object)
    end

    def get_entries(search_term: nil, filter: nil, sort_order: :asc, root_entries: false)
      return [] if object.initial_post_required?(current_user, session)
      Loaders::DiscussionEntryLoader.for(
        current_user: current_user,
        search_term: search_term,
        filter: filter,
        sort_order: sort_order,
        root_entries: root_entries
      ).load(object)
    end
  end
end
