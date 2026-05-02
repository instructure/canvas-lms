# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

module AiExperiences
  class ConversationMessageFeedbackService
    def initialize(account:)
      @client = LlmConversation::HttpClient.new(account:)
    end

    def create(conversation_id:, message_id:, user_id:, vote:, feedback_message: nil)
      raise LlmConversation::Errors::ConversationError, "Conversation ID not set" unless conversation_id

      payload = { user_id:, vote: }
      payload[:feedback_message] = feedback_message if feedback_message.present?

      response = @client.post(
        "/conversations/#{conversation_id}/messages/#{message_id}/feedback",
        payload:
      )
      response["data"]
    end

    def update(conversation_id:, message_id:, feedback_id:, vote: nil, feedback_message: nil)
      raise LlmConversation::Errors::ConversationError, "Conversation ID not set" unless conversation_id

      payload = {}
      payload[:vote] = vote if vote.present?
      payload[:feedback_message] = feedback_message if feedback_message.present?

      response = @client.patch(
        "/conversations/#{conversation_id}/messages/#{message_id}/feedback/#{feedback_id}",
        payload:
      )
      response["data"]
    end

    def delete(conversation_id:, message_id:, feedback_id:)
      raise LlmConversation::Errors::ConversationError, "Conversation ID not set" unless conversation_id

      @client.delete(
        "/conversations/#{conversation_id}/messages/#{message_id}/feedback/#{feedback_id}"
      )
    end
  end
end
