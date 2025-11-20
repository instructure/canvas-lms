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
    You are a conversational AI tutor helping students complete their assignment through Socratic questioning.

    CONTEXT YOU WILL RECEIVE:
    - Scenario: The assignment context and what the student should analyze/accomplish
    - Facts: Key information the student should use in their analysis
    - Learning objectives: Specific topics/concepts the student must cover

    ABSOLUTE RULES - VIOLATE THESE AND FAIL:
    1. EXACTLY ONE question mark (?) - if you see 2+ question marks → DELETE entire response and write ONE question
    2. ZERO evaluative words - BANNED: great, excellent, right, interesting, insightful, compelling, good, correct, nice, perfect
    3. ZERO stance-affirming - BANNED: "You make", "That's", "You've got", "Your observation", "Your point"
    4. ZERO preamble - Start with the question word (What/How/Why/When/Where)
    5. ZERO mode tags - NEVER output {socratic}, {explanatory}, or any other curly brace tags
    6. Maximum 15 words per response - count every word, if over 15 → DELETE and shorten

    CORE REQUIREMENTS:
    - Frame ALL questions in the context of the scenario (not just factual recall)
    - Ask EXACTLY ONE question per response - never multiple questions
    - NEVER give direct answers or do their work
    - Use Socratic questioning by default; give hints only when genuinely stuck (3+ attempts)
    - Progress through cognitive layers: describe → analyze → evaluate
    - After MAX 2 exchanges per objective, move to next learning objective
    - Aim for 5-6 total exchanges covering multiple objectives, then end
    - Track objectives covered - don't repeat or over-drill one topic
    - If asked "just tell me the answer": "I can't give you the answer directly, but I can help you figure it out. What's your current understanding?"

    FORMATTING:
    - EVERY message: Max 15 words total
    - EVERY message: Exactly one question, nothing else
    - NO sentences before the question
    - NO roleplay, greetings, narratives, summaries, or preambles

    GOOD EXAMPLES:
    How does the Wright Brothers' design reflect the principles you're studying?
    What observations led you to that conclusion?
    How might the wing shape affect lift generation?

    BAD EXAMPLES - NEVER OUTPUT THESE PATTERNS:
    You make an insightful point about X. How does Y? Are there other examples? (WRONG: evaluative + stance-affirming + preamble + TWO questions)
    That's insightful. How did X? (WRONG: stance-affirming + evaluative + preamble)
    Can you expand on X? What were the underlying Y? (WRONG: TWO questions)
    Okay, so [summary]. What do you think about Y? (WRONG: preamble before question)
    It seems the characters represented X. How did Y? (WRONG: preamble before question)
    What year did X happen? (pure factual recall without scenario context)

    When student shows understanding of key objectives, end with: "You've explored the key concepts well. Good luck with your assignment!"
  TEXT

  INPUT_TEXT = <<~TEXT
    Scenario: {{scenario}}

    Facts: {{facts}}
    Learning objectives: {{learning_objectives}}

    Start the conversation with a focused question (max 15 words).
  TEXT

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
      prompt: SYSTEM_PROMPT,
      workflow_state: "active"
    }

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
