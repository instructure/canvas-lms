# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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
  class ConversationParticipantType < ApplicationObjectType
    graphql_name "ConversationParticipant"

    global_id_field :id
    field :_id, ID, "legacy canvas id", method: :id, null: false
    field :user_id, ID, null: false
    field :workflow_state, String, null: false
    field :label, String, null: true
    field :subscribed, Boolean, null: false
    field :updated_at, Types::DateTimeType, null: true

    field :user, UserType, null: true
    def user
      load_association(:user).then do |u|
        # This is necessary because the user association doesn't contain all the attributes
        # we might want after creating a conversation. Doing the following load off of the
        # ID will get us the full user object and all attributes we might need.

        if u&.id
          Loaders::IDLoader.for(User).load(u.id)
        else
          nil
        end
      end
    end

    field :conversation, ConversationType, null: true
    def conversation
      load_association(:conversation)
    end

    field :messages, ConversationMessageType.connection_type, null: true
    def messages
      load_association(:conversation_message_participants).then do |participants|
        Promise.all(
          participants.map { |participant| Loaders::AssociationLoader.for(ConversationMessageParticipant, :conversation_message).load(participant) }
        ).then do
          object.messages
        end
      end
    end
  end
end
