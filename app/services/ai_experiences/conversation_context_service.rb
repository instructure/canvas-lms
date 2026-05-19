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
  class ConversationContextService
    PROMPT_CODE = "alpha"

    def initialize(account:)
      @client = LlmConversation::HttpClient.new(account:)
    end

    def create(ai_experience:)
      return if ai_experience.llm_conversation_context_id.present?

      prompt = get_prompt_by_code(PROMPT_CODE)

      payload = {
        type: "assignment",
        data: context_data(ai_experience),
        prompt_id: prompt["id"]
      }

      response = @client.post("/conversation-context", payload:)
      context_id = response.dig("data", "id")
      ai_experience.update_column(:llm_conversation_context_id, context_id)
      context_id
    end

    def update(ai_experience:)
      return unless ai_experience.llm_conversation_context_id.present?

      payload = { data: context_data(ai_experience) }
      @client.patch("/conversation-context/#{ai_experience.llm_conversation_context_id}", payload:)
    end

    def delete(ai_experience:)
      return unless ai_experience.llm_conversation_context_id.present?

      @client.delete("/conversation-context/#{ai_experience.llm_conversation_context_id}")
      ai_experience.update_column(:llm_conversation_context_id, nil)
    end

    private

    def get_prompt_by_code(code)
      response = @client.get("/prompts/by-code/#{code}")
      response["data"]
    end

    def context_data(ai_experience)
      data = {
        scenario: ai_experience.pedagogical_guidance,
        facts: ai_experience.facts,
        learning_objectives: ai_experience.learning_objective,
        root_account_uuid: ai_experience.course.root_account.uuid
      }

      if ai_experience.course.feature_enabled?(:ai_experiences_context_file_upload)
        data[:context_files] = ai_experience.context_files.reload.map do |file|
          {
            source: "canvas",
            sourceType: "file",
            sourceId: "file-#{file.global_id}",
            metadata: {
              courseId: ai_experience.course.global_id.to_s,
              title: file.display_name
            },
            url: file.public_url
          }
        end
      end

      data
    end
  end
end
