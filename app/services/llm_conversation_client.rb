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
    # Create a new conversation with prompt_code and conversation_context_id
    conversation = create_conversation
    @conversation_id = conversation["id"]

    # The conversation has first_message (the interpolated input_template)
    # We need to send it to get the AI's response
    first_message = conversation["first_message"]

    # Send the first message to get LLM response
    llm_response = add_message_to_conversation(first_message, "User")

    {
      conversation_id: @conversation_id,
      messages: [
        { role: "User", text: first_message },
        { role: "Assistant", text: llm_response }
      ]
    }
  end

  def continue_conversation(messages:, new_user_message:)
    # Send the new user message and get LLM response
    llm_response = add_message_to_conversation(new_user_message, "User")

    messages << { role: "User", text: new_user_message }
    messages << { role: "Assistant", text: llm_response }

    {
      conversation_id: @conversation_id,
      messages:
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

    # Convert llm-conversation message format to our format
    messages_data.map do |msg|
      {
        role: msg["is_llm_message"] ? "Assistant" : "User",
        text: msg["text"]
      }
    end
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
      workflow_state: "active"
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
      text: message_text
    }

    response = make_request(
      method: :post,
      path: "/conversations/#{@conversation_id}/messages/add",
      payload:,
      error_message: "Failed to add message"
    )

    response["data"]["text"]
  end
end
