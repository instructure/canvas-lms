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

class Mutations::DeleteConversations < Mutations::BaseMutation
  graphql_name "DeleteConversations"

  # input arguments
  argument :ids, [ID], required: true, prepare: GraphQLHelpers.relay_or_legacy_ids_prepare_func("Conversation")

  field :conversation_ids, [ID], null: true

  def resolve(input:)
    errors = {}
    context[:deleted_models] = { conversations: {} }
    # rubocop:disable Style/BlockDelimiters
    resolved_ids = input[:ids].filter_map { |id|
      conversation = Conversation.find_by(id:)
      if conversation.nil?
        errors[id] = "Unable to find Conversation"
        next
      end

      participant_record = current_user.all_conversations.find_by(conversation_id: conversation.id)
      if participant_record.nil?
        errors[id] = "Insufficient permissions"
        next
      end

      participant_record.remove_messages(:all)
      context[:deleted_models][:conversations][conversation.id] = conversation
      conversation.id
    }
    # rubocop:enable Style/BlockDelimiters

    response = {}
    response[:conversation_ids] = resolved_ids if resolved_ids.any?
    response[:errors] = errors if errors.any?
    response
  rescue ActiveRecord::RecordInvalid => e
    errors_for(e.record)
  end

  def self.conversation_ids_log_entry(entry, context)
    context[:deleted_models][:conversations][entry]
  end
end
