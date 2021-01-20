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

class Mutations::UpdateConversationParticipant < Mutations::BaseMutation
  graphql_name 'UpdateConversationParticipant'

  argument :conversation_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func('Conversation')

  # update params
  argument :starred, Boolean, required: false
  argument :subscribed, Boolean, required: false
  argument :workflow_state, String, required: false

  field :conversation_participant, Types::ConversationParticipantType, null: true
  def resolve(input:)
    conversation = Conversation.find(input[:conversation_id])

    conversation_participant = current_user.all_conversations.find_by(conversation: conversation)
    raise GraphQL::ExecutionError, "insufficient permissions" if conversation_participant.nil?

    update_params = {}
    update_params[:starred] = input[:starred] unless input[:starred].nil?
    update_params[:subscribed] = input[:subscribed] unless input[:subscribed].nil?
    update_params[:workflow_state] = input[:workflow_state] unless input[:workflow_state].nil?
    conversation_participant.update(update_params)

    {
      conversation_participant: conversation_participant
    }
  rescue ActiveRecord::RecordNotFound
    raise GraphQL::ExecutionError, 'Unable to find Conversation'
  rescue ActiveRecord::RecordInvalid => e
    errors_for(e.record)
  rescue => e
    validation_error(e.message)
  end
end
