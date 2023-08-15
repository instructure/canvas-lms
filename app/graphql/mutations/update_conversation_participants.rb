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

class Mutations::UpdateConversationParticipants < Mutations::BaseMutation
  graphql_name "UpdateConversationParticipants"

  argument :conversation_ids, [ID], required: true, prepare: GraphQLHelpers.relay_or_legacy_ids_prepare_func("Conversation")

  # update params
  argument :starred, Boolean, required: false
  argument :subscribed, Boolean, required: false
  argument :workflow_state, String, required: false

  field :conversation_participants, [Types::ConversationParticipantType], null: true
  def resolve(input:)
    update_params = {}
    update_params[:starred] = input[:starred] unless input[:starred].nil?
    update_params[:subscribed] = input[:subscribed] unless input[:subscribed].nil?
    update_params[:workflow_state] = input[:workflow_state] unless input[:workflow_state].nil?

    c_ids = Conversation.where(id: input[:conversation_ids]).pluck(:id).map(&:to_s)
    errors = (input[:conversation_ids] - c_ids).index_with { "Unable to find Conversation" }

    conversation_participants = current_user.all_conversations.where(conversation_id: c_ids)
    cp_ids = conversation_participants.map { |cp| cp.conversation_id.to_s }
    errors.merge!((c_ids - cp_ids).index_with { "Insufficient permissions" })

    # update_all cannot be used as the ConversationParticipant model
    # extends the methods used for updating attributes due to the
    # storage of data differing from what ActiveRecord expects
    unarchivable_states = ["unread", "read"]
    conversation_participants.map do |cp|
      InstStatsd::Statsd.increment("inbox.conversation.unarchived.react") if cp.workflow_state == "archived" && unarchivable_states.include?(update_params[:workflow_state])
      cp.update(update_params)
    end
    InstStatsd::Statsd.count("inbox.conversation.archived.react", conversation_participants.count) if update_params[:workflow_state] == "archived"
    InstStatsd::Statsd.count("inbox.conversation.starred.react", conversation_participants.count) if update_params[:starred] == true
    InstStatsd::Statsd.count("inbox.conversation.unstarred.react", conversation_participants.count) if update_params[:starred] == false
    InstStatsd::Statsd.count("inbox.conversation.unread.react", conversation_participants.count) if update_params[:workflow_state] == "unread"

    response = {}
    response[:conversation_participants] = conversation_participants if conversation_participants.any?
    response[:errors] = errors if errors.any?
    response
  rescue ActiveRecord::RecordInvalid => e
    errors_for(e.record)
  rescue => e
    validation_error(e.message)
  end
end
