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
  class ConversationContinueService
    def initialize(account:)
      @client = LlmConversation::HttpClient.new(account:)
    end

    def continue(conversation_id:, new_user_message:, requesting_user: nil)
      raise LlmConversation::Errors::ConversationError, "Conversation ID not set" unless conversation_id

      llm_response = add_message(conversation_id:, message_text: new_user_message)
      refreshed = fetch_messages(conversation_id:, include_feedback_from: requesting_user&.uuid)

      {
        conversation_id:,
        messages: refreshed[:messages],
        progress: llm_response[:progress] || refreshed[:progress]
      }
    end

    private

    def add_message(conversation_id:, message_text:)
      payload = {
        role: "User",
        text: message_text,
        include_progress: true
      }

      response = @client.post("/conversations/#{conversation_id}/messages/add", payload:)
      response_data = response["data"]

      progress = extract_progress(response_data["learning_objective_progress"]) if response_data["learning_objective_progress"]

      { text: response_data["text"], progress: }
    end

    def fetch_messages(conversation_id:, include_feedback_from: nil)
      path = "/conversations/#{conversation_id}/messages"
      path += "?include_feedback_from=#{CGI.escape(include_feedback_from)}" if include_feedback_from

      response = @client.get(path)
      messages_data = response["data"]

      progress = nil
      if messages_data.any? && messages_data.last["learning_objective_progress"]
        progress = extract_progress(messages_data.last["learning_objective_progress"])
      end

      formatted_messages = messages_data.map do |msg|
        base = {
          id: msg["id"],
          role: msg["is_llm_message"] ? "Assistant" : "User",
          text: msg["text"]
        }
        base[:feedback] = msg["feedback"] || [] if include_feedback_from
        base
      end

      { messages: formatted_messages, progress: }
    end

    def extract_progress(progress_data)
      return nil unless progress_data

      objectives = progress_data["objectives"] || []
      covered_count = objectives.count { |obj| obj["status"] == "covered" }
      total_count = objectives.length

      {
        current: covered_count,
        total: total_count,
        percentage: total_count.positive? ? ((covered_count.to_f / total_count) * 100).round : 0,
        objectives:
      }
    end
  end
end
