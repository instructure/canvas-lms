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

class Mutations::DeleteConversation < Mutations::BaseMutation
  graphql_name "DeleteConversation"

  # input arguments
  argument :id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func('Conversation')

  field :conversation_id, ID, null: false

  def resolve(input:)
    conversation = Conversation.find_by(id: input[:id])
    raise GraphQL::ExecutionError, "Unable to find Conversation" if conversation.nil?

    participant_record = current_user.all_conversations.find_by(conversation_id: conversation.id)
    raise GraphQL::ExecutionError, "insufficient permissions" if participant_record.nil?

    participant_record.remove_messages(:all)
    {conversation_id: conversation.id}

  rescue ActiveRecord::RecordInvalid => invalid
    errors_for(invalid.record)
  end
end
