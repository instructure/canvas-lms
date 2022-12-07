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
  class ConversationMessageType < ApplicationObjectType
    graphql_name "ConversationMessage"

    global_id_field :id
    field :_id, ID, "legacy canvas id", method: :id, null: false
    field :conversation_id, ID, null: false
    field :body, String, null: false
    field :created_at, Types::DateTimeType, null: true

    field :author, UserType, null: true
    def author
      load_association(:author)
    end

    field :recipients, [UserType], null: false
    def recipients
      load_association(:conversation_message_participants).then do |cmps|
        # handle case where user sent a message to themself or if cmp is bad ex: hard deleted user.
        cmps = cmps.reject { |cmp| cmp.user_id == current_user.id || !cmp.active? || cmp.user.nil? } unless cmps.size == 1
        Loaders::AssociationLoader.for(ConversationMessageParticipant, :user).load_many(cmps)
      end
    end

    field :media_comment, MediaObjectType, null: true
    def media_comment
      Loaders::MediaObjectLoader.load(object.media_comment_id)
    end

    field :attachments_connection, Types::FileType.connection_type, null: true
    def attachments_connection
      load_association(:attachment_associations).then do |attachment_associations|
        Loaders::AssociationLoader.for(AttachmentAssociation, :attachment).load_many(attachment_associations)
      end
    end
  end
end
