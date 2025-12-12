# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

# Manages conversation contexts in the llm-conversation service
# Each AiExperience has one ConversationContext that stores its facts, scenario, and learning objectives
class LLMConversationContextManager
  def self.create_context(ai_experience:)
    new(ai_experience:).create_context
  end

  def self.update_context(ai_experience:)
    new(ai_experience:).update_context
  end

  def self.delete_context(ai_experience:)
    new(ai_experience:).delete_context
  end

  def initialize(ai_experience:)
    @ai_experience = ai_experience
  end

  def create_context
    return if @ai_experience.llm_conversation_context_id.present?

    # Look up the prompt to get its ID
    prompt = get_prompt_by_code(LLMConversationClient::PROMPT_CODE)

    payload = {
      type: "assignment", # Use 'assignment' type for AI experiences (valid enum value)
      data: context_data,
      prompt_id: prompt["id"]
    }

    response = make_request(
      method: :post,
      path: "/conversation-context",
      payload:,
      error_message: "Failed to create conversation context"
    )

    context_id = response.dig("data", "id")
    @ai_experience.update_column(:llm_conversation_context_id, context_id)
    context_id
  end

  def update_context
    return unless @ai_experience.llm_conversation_context_id.present?

    payload = {
      data: context_data
    }

    make_request(
      method: :patch,
      path: "/conversation-context/#{@ai_experience.llm_conversation_context_id}",
      payload:,
      error_message: "Failed to update conversation context"
    )
  end

  def delete_context
    return unless @ai_experience.llm_conversation_context_id.present?

    make_request(
      method: :delete,
      path: "/conversation-context/#{@ai_experience.llm_conversation_context_id}",
      error_message: "Failed to delete conversation context"
    )

    @ai_experience.update_column(:llm_conversation_context_id, nil)
  end

  private

  def context_data
    {
      scenario: @ai_experience.pedagogical_guidance,
      facts: @ai_experience.facts,
      learning_objectives: @ai_experience.learning_objective
    }
  end

  def get_prompt_by_code(code)
    response = make_request(
      method: :get,
      path: "/prompts/by-code/#{code}",
      error_message: "Failed to get prompt by code"
    )
    response["data"]
  end

  def make_request(method:, path:, error_message:, payload: nil)
    uri = URI("#{LLMConversationClient.base_url}#{path}")
    http = Net::HTTP.new(uri.host, uri.port)

    if uri.scheme.casecmp?("https")
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    end

    token = LLMConversationClient.bearer_token
    if token.nil?
      raise LlmConversation::Errors::ConversationError, "llm_conversation_bearer_token not found in vault secrets"
    end

    headers = {
      "Content-Type" => "application/json",
      "Authorization" => "Bearer #{token}"
    }

    request = case method
              when :get
                Net::HTTP::Get.new(uri.path, headers)
              when :post
                req = Net::HTTP::Post.new(uri.path, headers)
                req.body = payload.to_json if payload
                req
              when :patch
                req = Net::HTTP::Patch.new(uri.path, headers)
                req.body = payload.to_json if payload
                req
              when :delete
                Net::HTTP::Delete.new(uri.path, headers)
              end

    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      raise LlmConversation::Errors::ConversationError, "#{error_message}: #{response.code} - #{response.body}"
    end

    JSON.parse(response.body)
  rescue LlmConversation::Errors::ConversationError
    raise
  rescue Timeout::Error, SocketError, SystemCallError, OpenSSL::SSL::SSLError, JSON::ParserError, EOFError, Net::HTTPBadResponse, Net::ProtocolError => e
    raise LlmConversation::Errors::ConversationError, "#{error_message}: #{e.message}"
  end
end
