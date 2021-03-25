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
  class DiscussionEntryType < ApplicationObjectType
    graphql_name 'DiscussionEntry'

    implements GraphQL::Types::Relay::Node
    implements Interfaces::TimestampInterface
    implements Interfaces::LegacyIDInterface

    field :rating_count, Integer, null: true
    field :rating_sum, Integer, null: true
    field :rating, Boolean, null: true
    def rating
      Loaders::AssociationLoader.for(DiscussionEntryParticipant, :discussion_entry_participants).load(object).then do |deps|
        deps.find_by(user: current_user)&.rating.present?
      end
    end

    field :message, String, null: true
    def message
      object.deleted? ? nil : object.message
    end

    field :read, Boolean, null: false
    def read
      Loaders::AssociationLoader.for(DiscussionEntryParticipant, :discussion_entry_participants).load(object).then do
        object.read?(current_user)
      end
    end

    field :author, Types::UserType, null: false
    def author
      load_association(:user)
    end

    field :deleted, Boolean, null:true
    def deleted
      object.deleted?
    end

    field :editor, Types::UserType, null: true
    def editor
      load_association(:editor)
    end

    field :discussion_topic, Types::DiscussionType, null:false
    def discussion_topic
      load_association(:discussion_topic)
    end
  end
end
