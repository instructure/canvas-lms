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
  SYSTEM_PROMPT = <<~TEXT
    You are a conversational AI tutor helping students complete their assignment.

    Your goal: Help students meet the learning objectives through questions and guidance.

    CRITICAL RULES - YOU MUST FOLLOW THESE:
    1. NEVER give direct answers, summaries, or do their work - even if they ask explicitly
    2. If asked for "the answer" or to "just tell me", respond ONLY: "I can't give you the answer directly, but I can help you figure it out. What's your current understanding?"
    3. Ask questions that prompt thinking and discovery
    4. Give small hints only when students are genuinely stuck
    5. Keep discussions on-topic
    6. Reject inappropriate or off-topic requests
    7. Never request personal information

    CRITICAL FORMATTING RULES - STRICTLY ENFORCE:
    - First message: MAXIMUM 15 words. Just ask what they know or give a focused starting question.
    - Every response: MAXIMUM 2-3 SHORT sentences. No exceptions.
    - NO roleplay, greetings like "Hello and welcome", narrative descriptions, or museum guide personas
    - Be direct, conversational, and task-focused

    GOOD EXAMPLES:
    First message: What do you already know about the Wright Brothers' first flight?
    Follow-up: Right! Now, what problems did early aviators face with control?
    When asked for answer: I can't give you the answer directly, but I can help you figure it out. What's your current understanding?

    BAD EXAMPLES:
    Hello, and welcome to our museum exhibit... (too long, too formal)
    Excellent, you've got the key facts! Let me dive a bit deeper... (too verbose)
    Okay, let me summarize the key points... (giving the answer)

    Adapt your role to match the instructor's scenario, but ALWAYS follow these rules.
  TEXT

  INPUT_TEXT = <<~TEXT
    {{scenario}}

    Facts: {{facts}}
    Learning objectives: {{learning_objectives}}

    Start the conversation with a focused question (max 15 words).
  TEXT

  def self.base_url
    url = Setting.get("llm_conversation_base_url", nil)
    if url.nil?
      raise LlmConversation::Errors::ConversationError, "llm_conversation_base_url setting is not configured"
    end

    url
  end

  def initialize(current_user: nil, root_account_uuid: nil, facts: "", learning_objectives: "", scenario: "", conversation_id: nil)
    @root_account_uuid = root_account_uuid
    @current_user = current_user
    @facts = facts
    @learning_objectives = learning_objectives
    @scenario = scenario
    @conversation_id = conversation_id
  end

  def build_input_text
    INPUT_TEXT
      .gsub("{{facts}}", @facts)
      .gsub("{{learning_objectives}}", @learning_objectives)
      .gsub("{{scenario}}", @scenario)
  end

  def starting_messages
    initial_message = build_input_text

    # Create a new conversation in the llm-conversation service
    conversation = create_conversation
    @conversation_id = conversation["id"]

    # Send the initial user message and get LLM response
    llm_response = add_message_to_conversation(initial_message, "User")

    {
      conversation_id: @conversation_id,
      messages: [
        { role: "User", text: initial_message },
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

    uri = URI("#{self.class.base_url}/conversations/#{@conversation_id}/messages")
    http = Net::HTTP.new(uri.host, uri.port)
    headers = { "Content-Type" => "application/json" }
    request = Net::HTTP::Get.new(uri.path, headers)

    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      raise LlmConversation::Errors::ConversationError, "Failed to get messages: #{response.code} - #{response.body}"
    end

    parsed_response = JSON.parse(response.body)
    messages_data = parsed_response["data"]

    # Convert llm-conversation message format to our format
    messages_data.map do |msg|
      {
        role: msg["is_llm_message"] ? "Assistant" : "User",
        text: msg["text"]
      }
    end
  rescue LlmConversation::Errors::ConversationError
    raise
  rescue Timeout::Error, SocketError, SystemCallError, OpenSSL::SSL::SSLError, JSON::ParserError => e
    raise LlmConversation::Errors::ConversationError, "Failed to get messages: #{e.message}"
  end

  private

  def create_conversation
    uri = URI("#{self.class.base_url}/conversations")
    http = Net::HTTP.new(uri.host, uri.port)
    headers = { "Content-Type" => "application/json" }
    request = Net::HTTP::Post.new(uri.path, headers)

    payload = {
      root_account_id: @root_account_uuid || "default",
      account_id: @root_account_uuid || "default",
      user_id: @current_user&.uuid || "anonymous",
      prompt: SYSTEM_PROMPT,
      workflow_state: "active"
    }

    request.body = payload.to_json
    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      raise LlmConversation::Errors::ConversationError, "Failed to create conversation: #{response.code} - #{response.body}"
    end

    JSON.parse(response.body)["data"]
  rescue LlmConversation::Errors::ConversationError
    raise
  rescue Timeout::Error, SocketError, SystemCallError, OpenSSL::SSL::SSLError, JSON::ParserError => e
    raise LlmConversation::Errors::ConversationError, "Failed to create conversation: #{e.message}"
  end

  def add_message_to_conversation(message_text, role)
    raise LlmConversation::Errors::ConversationError, "Conversation ID not set" unless @conversation_id

    uri = URI("#{self.class.base_url}/conversations/#{@conversation_id}/messages/add")
    http = Net::HTTP.new(uri.host, uri.port)
    headers = { "Content-Type" => "application/json" }
    request = Net::HTTP::Post.new(uri.path, headers)

    payload = {
      role:,
      text: message_text
    }

    request.body = payload.to_json
    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      raise LlmConversation::Errors::ConversationError, "Failed to add message: #{response.code} - #{response.body}"
    end

    parsed_response = JSON.parse(response.body)
    parsed_response["data"]["text"]
  rescue LlmConversation::Errors::ConversationError
    raise
  rescue Timeout::Error, SocketError, SystemCallError, OpenSSL::SSL::SSLError, JSON::ParserError => e
    raise LlmConversation::Errors::ConversationError, "Failed to add message to conversation: #{e.message}"
  end
end
