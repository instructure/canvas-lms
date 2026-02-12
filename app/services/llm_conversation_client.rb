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

require "net/http"
require "json"
require "uri"

class LLMConversationClient
  PROMPT_CODE = "alpha"

  def self.base_url
    url = resolve_base_url
    raise LlmConversation::Errors::ConversationError, base_url_error_message if url.nil?

    url
  end

  def self.resolve_base_url
    region = ApplicationController.region
    test_cluster = ApplicationController.test_cluster_name

    # Try beta-specific setting first if in beta or test cluster
    return Setting.get("llm_conversation_base_url_beta_#{region}", nil) if test_cluster.present? && region.present?

    # Fall back to production region-specific setting
    return Setting.get("llm_conversation_base_url_#{region}", nil) if region.present?

    # Fall back to base setting
    Setting.get("llm_conversation_base_url", nil)
  end

  def self.base_url_error_message
    region = ApplicationController.region
    test_cluster = ApplicationController.test_cluster_name

    if test_cluster.present? && region.present?
      "None of llm_conversation_base_url_beta_#{region}, llm_conversation_base_url_#{region}, or llm_conversation_base_url setting is configured"
    elsif region.present?
      "Neither llm_conversation_base_url_#{region} nor llm_conversation_base_url setting is configured"
    else
      "llm_conversation_base_url setting is not configured"
    end
  end
  private_class_method :resolve_base_url, :base_url_error_message

  def self.bearer_token
    Rails.application.credentials.llm_conversation_bearer_token
  end

  def initialize(current_user: nil, root_account_uuid: nil, facts: "", learning_objectives: "", scenario: "", conversation_id: nil, conversation_context_id: nil)
    @root_account_uuid = root_account_uuid
    @current_user = current_user
    @facts = facts
    @learning_objectives = learning_objectives
    @scenario = scenario
    @conversation_id = conversation_id
    @conversation_context_id = conversation_context_id
  end

  def starting_messages
    # Create a new conversation with auto_initialize: true
    # This will create the conversation and immediately generate the first message and response
    conversation = create_conversation
    @conversation_id = conversation["id"]

    Rails.logger.info "=== LLMConversationClient#starting_messages DEBUG ==="
    Rails.logger.info "Conversation ID: #{@conversation_id}"
    Rails.logger.info "Conversation has learning_objective_progress: #{conversation["learning_objective_progress"].present?}"
    Rails.logger.info "Conversation learning_objective_progress: #{conversation["learning_objective_progress"].inspect}"

    # With auto_initialize, messages already exist - just fetch them
    messages_data = messages

    Rails.logger.info "Messages data progress: #{messages_data[:progress].inspect}"

    # If messages don't have progress, get it from the conversation object
    progress = messages_data[:progress]
    if progress.nil? && conversation["learning_objective_progress"]
      Rails.logger.info "Extracting progress from conversation object"
      progress = extract_progress_from_data(conversation["learning_objective_progress"])
      Rails.logger.info "Extracted progress: #{progress.inspect}"
    end

    result = {
      conversation_id: @conversation_id,
      messages: messages_data[:messages],
      progress:
    }

    Rails.logger.info "Final result progress: #{result[:progress].inspect}"
    Rails.logger.info "=== END DEBUG ==="

    result
  end

  def continue_conversation(messages:, new_user_message:)
    # Send the new user message and get LLM response
    llm_response = add_message_to_conversation(new_user_message, "User")

    messages << { role: "User", text: new_user_message }
    messages << { role: "Assistant", text: llm_response[:text] }

    {
      conversation_id: @conversation_id,
      messages:,
      progress: llm_response[:progress]
    }
  end

  def messages
    raise LlmConversation::Errors::ConversationError, "Conversation ID not set" unless @conversation_id

    response = make_request(
      method: :get,
      path: "/conversations/#{@conversation_id}/messages",
      error_message: "Failed to get messages"
    )

    messages_data = response["data"]

    # Extract progress from the last message (if available)
    progress = nil
    if messages_data.any? && messages_data.last["learning_objective_progress"]
      progress = extract_progress_from_data(messages_data.last["learning_objective_progress"])
    end

    # Convert llm-conversation message format to our format
    formatted_messages = messages_data.map do |msg|
      {
        role: msg["is_llm_message"] ? "Assistant" : "User",
        text: msg["text"]
      }
    end

    {
      messages: formatted_messages,
      progress:
    }
  end

  def messages_with_conversation_progress
    raise LlmConversation::Errors::ConversationError, "Conversation ID not set" unless @conversation_id

    # Get messages first
    messages_result = messages

    # If no progress on messages, fetch from conversation object
    progress = messages_result[:progress]
    if progress.nil?
      conversation_response = make_request(
        method: :get,
        path: "/conversations/#{@conversation_id}",
        error_message: "Failed to get conversation"
      )

      if conversation_response["data"] && conversation_response["data"]["learning_objective_progress"]
        progress = extract_progress_from_data(conversation_response["data"]["learning_objective_progress"])
      end
    end

    {
      messages: messages_result[:messages],
      progress:
    }
  end

  def evaluation
    raise LlmConversation::Errors::ConversationError, "Conversation ID not set" unless @conversation_id

    response = make_request(
      method: :post,
      path: "/conversations/#{@conversation_id}/evaluate",
      error_message: "Failed to evaluate conversation"
    )

    response["data"]
  end

  private

  def make_request(method:, path:, payload: nil, error_message:)
    uri = URI("#{self.class.base_url}#{path}")
    http = Net::HTTP.new(uri.host, uri.port)

    # Configure SSL for HTTPS
    if uri.scheme.casecmp?("https")
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    end

    token = self.class.bearer_token
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

  def create_conversation
    payload = {
      root_account_id: @root_account_uuid || "default",
      account_id: @root_account_uuid || "default",
      user_id: @current_user&.uuid || "anonymous",
      prompt_code: PROMPT_CODE,
      workflow_state: "active",
      auto_initialize: true
    }

    # Add conversation_context_id if provided
    payload[:conversation_context_id] = @conversation_context_id if @conversation_context_id

    # Add variables for prompt interpolation if not using conversation_context
    unless @conversation_context_id
      payload[:variables] = {
        scenario: @scenario,
        facts: @facts,
        learning_objectives: @learning_objectives
      }
    end

    response = make_request(
      method: :post,
      path: "/conversations",
      payload:,
      error_message: "Failed to create conversation"
    )

    response["data"]
  end

  def add_message_to_conversation(message_text, role)
    raise LlmConversation::Errors::ConversationError, "Conversation ID not set" unless @conversation_id

    payload = {
      role:,
      text: message_text,
      include_progress: true
    }

    response = make_request(
      method: :post,
      path: "/conversations/#{@conversation_id}/messages/add",
      payload:,
      error_message: "Failed to add message"
    )

    response_data = response["data"]

    # Extract progress if available
    progress = nil
    if response_data["learning_objective_progress"]
      progress = extract_progress_from_data(response_data["learning_objective_progress"])
    end

    {
      text: response_data["text"],
      progress:
    }
  end

  def extract_progress_from_data(progress_data)
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
