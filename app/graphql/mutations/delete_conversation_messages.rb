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

class Mutations::DeleteConversationMessages < Mutations::BaseMutation
  graphql_name "DeleteConversationMessages"

  # input arguments
  argument :ids, [ID], required: true, prepare: GraphQLHelpers.relay_or_legacy_ids_prepare_func('ConversationMessage')

  field :conversation_message_ids, [ID], null: false

  def resolve(input:)
    messages = ConversationMessage.preload(:conversation).find(input[:ids])
    if messages.map(&:conversation).uniq.length > 1
      raise GraphQL::ExecutionError, "All ConversationMessages must exist within the same Conversation"
    end

    participant_record = current_user.all_conversations.find_by(conversation_id: messages.first.conversation.id)
    raise GraphQL::ExecutionError, "Insufficient permissions" if participant_record.nil?

    participant_record.remove_messages(*messages)
    {conversation_message_ids: input[:ids]}
  rescue ActiveRecord::RecordInvalid => e
    errors_for(e.record)
  rescue ActiveRecord::RecordNotFound
    raise GraphQL::ExecutionError, "Unable to find ConversationMessage"
  end
end
