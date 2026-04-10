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
  class ConversationStartService
    PROMPT_CODE = "alpha"

    def initialize
      @client = LlmConversation::HttpClient.new
    end

    def start(current_user:, root_account_uuid:, conversation_context_id: nil, facts: "", learning_objectives: "", scenario: "")
      conversation = create_conversation(
        current_user:,
        root_account_uuid:,
        conversation_context_id:,
        facts:,
        learning_objectives:,
        scenario:
      )
      conversation_id = conversation["id"]

      Rails.logger.info "=== AiExperiences::ConversationStartService#start DEBUG ==="
      Rails.logger.info "Conversation ID: #{conversation_id}"
      Rails.logger.info "Conversation has learning_objective_progress: #{conversation["learning_objective_progress"].present?}"
      Rails.logger.info "Conversation learning_objective_progress: #{conversation["learning_objective_progress"].inspect}"

      messages_result = fetch_messages(conversation_id:)

      Rails.logger.info "Messages data progress: #{messages_result[:progress].inspect}"

      progress = messages_result[:progress]
      if progress.nil? && conversation["learning_objective_progress"]
        Rails.logger.info "Extracting progress from conversation object"
        progress = extract_progress(conversation["learning_objective_progress"])
        Rails.logger.info "Extracted progress: #{progress.inspect}"
      end

      result = {
        conversation_id:,
        messages: messages_result[:messages],
        progress:
      }

      Rails.logger.info "Final result progress: #{result[:progress].inspect}"
      Rails.logger.info "=== END DEBUG ==="

      result
    end

    private

    def create_conversation(current_user:, root_account_uuid:, conversation_context_id:, facts:, learning_objectives:, scenario:)
      payload = {
        root_account_id: root_account_uuid || "default",
        account_id: root_account_uuid || "default",
        user_id: current_user&.uuid || "anonymous",
        prompt_code: PROMPT_CODE,
        workflow_state: "active",
        auto_initialize: true
      }

      if conversation_context_id
        payload[:conversation_context_id] = conversation_context_id
      else
        payload[:variables] = {
          scenario:,
          facts:,
          learning_objectives:
        }
      end

      response = @client.post("/conversations", payload:)
      response["data"]
    end

    def fetch_messages(conversation_id:)
      response = @client.get("/conversations/#{conversation_id}/messages")
      messages_data = response["data"]

      progress = nil
      if messages_data.any? && messages_data.last["learning_objective_progress"]
        progress = extract_progress(messages_data.last["learning_objective_progress"])
      end

      formatted_messages = messages_data.map do |msg|
        {
          id: msg["id"],
          role: msg["is_llm_message"] ? "Assistant" : "User",
          text: msg["text"]
        }
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
