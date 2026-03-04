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

  def self.sync_index_status(ai_experience:)
    new(ai_experience:).sync_index_status
  end

  def self.trigger_indexing(ai_experience:, context_file_ids: nil)
    new(ai_experience:).trigger_indexing(context_file_ids)
  end

  def self.remove_documents(ai_experience:, context_files:)
    new(ai_experience:).remove_documents(context_files)
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

  def sync_index_status
    return unless @ai_experience.llm_conversation_context_id.present?
    return unless @ai_experience.course.feature_enabled?(:ai_experiences_context_file_upload)

    response = make_request(
      method: :get,
      path: "/contexts/#{@ai_experience.llm_conversation_context_id}/documents",
      error_message: "Failed to fetch document index status"
    )

    documents = response["documents"] || []
    return if documents.empty?

    statuses = documents.pluck("status")
    new_status = if statuses.all?("completed")
                   "completed"
                 elsif statuses.any?("failed")
                   "failed"
                 else
                   "in_progress"
                 end

    @ai_experience.update_column(:context_index_status, new_status)
    new_status
  rescue LlmConversation::Errors::ConversationError => e
    Rails.logger.warn("Document index status sync failed for ai_experience #{@ai_experience.id}: #{e.message}")
  end

  def trigger_indexing(context_file_ids = nil)
    context_id = @ai_experience.llm_conversation_context_id
    return unless context_id.present?

    scope = @ai_experience.ai_experience_context_files
    scope = scope.where(id: context_file_ids) if context_file_ids.present?
    context_file_records = scope.preload(:attachment)
    return if context_file_records.empty?

    context_file_records.each do |context_file|
      file = context_file.attachment
      next if file.nil? || file.file_state == "deleted"

      response = make_request(
        method: :post,
        path: "/contexts/#{context_id}/documents",
        payload: { url: file.public_url, sourceType: "file" },
        error_message: "Failed to trigger indexing for file #{file.id}"
      )

      doc_id = response["id"]
      context_file.update_column(:llm_conversation_service_document_id, doc_id) if doc_id.present?
    end

    @ai_experience.update_column(:context_index_status, "in_progress")
  end

  def remove_documents(context_files)
    context_id = @ai_experience.llm_conversation_context_id
    return unless context_id.present?
    return unless @ai_experience.course.feature_enabled?(:ai_experiences_context_file_upload)

    context_files.each do |context_file|
      next if context_file.llm_conversation_service_document_id.blank?

      make_request(
        method: :delete,
        path: "/contexts/#{context_id}/documents/#{context_file.llm_conversation_service_document_id}",
        error_message: "Failed to remove document #{context_file.llm_conversation_service_document_id}"
      )
    end
  end

  private

  def context_data
    data = {
      scenario: @ai_experience.pedagogical_guidance,
      facts: @ai_experience.facts,
      learning_objectives: @ai_experience.learning_objective,
      root_account_uuid: @ai_experience.course.root_account.uuid
    }

    if @ai_experience.course.feature_enabled?(:ai_experiences_context_file_upload)
      data[:context_files] = @ai_experience.context_files.map do |file|
        {
          source: "canvas",
          sourceType: "file",
          sourceId: "file-#{file.global_id}",
          metadata: {
            courseId: @ai_experience.course.global_id.to_s,
            title: file.display_name
          },
          url: file.public_url
        }
      end
    end

    data
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

    response.body.present? ? JSON.parse(response.body) : {}
  rescue LlmConversation::Errors::ConversationError
    raise
  rescue Timeout::Error, SocketError, SystemCallError, OpenSSL::SSL::SSLError, JSON::ParserError, EOFError, Net::HTTPBadResponse, Net::ProtocolError => e
    raise LlmConversation::Errors::ConversationError, "#{error_message}: #{e.message}"
  end
end
