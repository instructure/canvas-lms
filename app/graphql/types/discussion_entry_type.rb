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

module Types
  class ReplyPreviewDataType < ApplicationObjectType
    graphql_name 'ReplyPreviewDataType'

    field :author_name, String, null: false
    field :created_at, Types::DateTimeType, null: false
    field :message, String, null: false
  end

  class DiscussionEntryType < ApplicationObjectType
    graphql_name 'DiscussionEntry'

    implements GraphQL::Types::Relay::Node
    implements Interfaces::TimestampInterface
    implements Interfaces::LegacyIDInterface

    field :discussion_topic_id, ID, null: false
    field :parent_id, ID, null: true
    field :root_entry_id, ID, null: true
    field :rating_count, Integer, null: true
    field :rating_sum, Integer, null: true
    field :rating, Boolean, null: true
    def rating
      Loaders::AssociationLoader.for(DiscussionEntryParticipant, :discussion_entry_participants).load(object).then do |deps|
        r = deps.find_by(user: current_user)&.rating
        !r.nil? && r == 1
      end
    end

    field :message, String, null: true
    def message
      if object.deleted?
        nil
      elsif object.include_reply_preview && Account.site_admin.feature_enabled?(:isolated_view)
        load_association(:parent_entry).then do |parent|
          Loaders::AssociationLoader.for(DiscussionEntry, :user).load(parent).then do
            parent.quoted_reply_html + object.message
          end
        end
      else
        object.message
      end
    end

    field :reply_preview_data, Types::ReplyPreviewDataType, null: true
    def reply_preview_data
      if object.deleted?
        nil
      elsif object.include_reply_preview && Account.site_admin.feature_enabled?(:isolated_view)
        load_association(:parent_entry).then do |parent|
          Loaders::AssociationLoader.for(DiscussionEntry, :user).load(parent).then do
            parent.reply_preview_data
          end
        end
      else
        nil
      end
    end

    field :reply_preview, String, null: true
    def reply_preview
      if object.parent_id? && Account.site_admin.feature_enabled?(:isolated_view)
        Promise.all([load_association(:user), load_association(:editor)]).then do
          object.quoted_reply_html
        end
      end
    end

    field :read, Boolean, null: false
    def read
      Loaders::AssociationLoader.for(DiscussionEntryParticipant, :discussion_entry_participants).load(object).then do
        object.read?(current_user)
      end
    end

    field :forced_read_state, Boolean, null: true
    def forced_read_state
      Loaders::AssociationLoader.for(DiscussionEntryParticipant, :discussion_entry_participants).load(object).then do |deps|
        !!deps.find_by(user: current_user)&.forced_read_state
      end
    end

    field :author, Types::UserType, null: false
    def author
      load_association(:user)
    end

    field :deleted, Boolean, null: true
    def deleted
      object.deleted?
    end

    field :editor, Types::UserType, null: true
    def editor
      load_association(:editor)
    end

    field :root_entry_participant_counts, Types::DiscussionEntryCountsType, null: true
    def root_entry_participant_counts
      return nil unless object.root_entry_id.nil?

      Loaders::DiscussionEntryCountsLoader.for(current_user: current_user).load(object)
    end

    field :discussion_topic, Types::DiscussionType, null: false
    def discussion_topic
      load_association(:discussion_topic)
    end

    field :discussion_subentries_connection, Types::DiscussionEntryType.connection_type, null: true do
      argument :sort_order, DiscussionSortOrderType, required: false
      argument :relative_entry_id, ID, required: false
      argument :before_relative_entry, Boolean, required: false
      argument :include_relative_entry, Boolean, required: false
    end
    def discussion_subentries_connection(sort_order: :asc, relative_entry_id: nil, before_relative_entry: true, include_relative_entry: true)
      # don't try to load subentries UNLESS
      # we are a legacy discussion entry, or we are a root_entry.
      return nil unless object.legacy? || object.root_entry_id.nil?

      Loaders::DiscussionEntryLoader.for(
        current_user: current_user,
        sort_order: sort_order,
        relative_entry_id: relative_entry_id,
        before_relative_entry: before_relative_entry,
        include_relative_entry: include_relative_entry
      ).load(object)
    end

    field :parent, Types::DiscussionEntryType, null: true
    def parent
      load_association(:parent_entry)
    end

    field :attachment, Types::FileType, null: true
    def attachment
      load_association(:attachment)
    end

    field :last_reply, Types::DiscussionEntryType, null: true
    def last_reply
      return nil unless object.root_entry_id.nil?

      load_association(:last_discussion_subentry)
    end

    field :subentries_count, Integer, null: true
    def subentries_count
      # don't try to count subentries UNLESS
      # we are a legacy discussion entry, or we are a root_entry
      return nil unless object.legacy? || object.root_entry_id.nil?

      Loaders::AssociationCountLoader.for(DiscussionEntry, :discussion_subentries).load(object)
    end

    field :permissions, Types::DiscussionEntryPermissionsType, null: true
    def permissions
      load_association(:discussion_topic).then do
        {
          loader: Loaders::PermissionsLoader.for(object, current_user: current_user, session: session),
          discussion_entry: object
        }
      end
    end

    field :root_entry, Types::DiscussionEntryType, null: true
    def root_entry
      load_association(:root_entry)
    end
  end
end
