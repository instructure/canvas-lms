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

require "spec_helper"
require "webmock/rspec"
require_relative "../../lib/llm_conversation"
require_relative "../../lib/llm_conversation/errors"

describe LLMConversationClient do
  let(:user) { user_model }
  let(:root_account_uuid) { "test-account-uuid" }
  let(:facts) { "Test facts" }
  let(:learning_objectives) { "Test learning objectives" }
  let(:scenario) { "Test scenario" }
  let(:conversation_id) { "test-conversation-id" }

  let(:client) do
    described_class.new(
      current_user: user,
      root_account_uuid:,
      facts:,
      learning_objectives:,
      scenario:
    )
  end

  let(:client_with_conversation_id) do
    described_class.new(
      current_user: user,
      root_account_uuid:,
      facts:,
      learning_objectives:,
      scenario:,
      conversation_id:
    )
  end

  describe ".base_url" do
    it "raises error when setting is not configured" do
      expect { described_class.base_url }.to raise_error(
        LlmConversation::Errors::ConversationError,
        "llm_conversation_base_url setting is not configured"
      )
    end

    it "returns the configured setting value" do
      Setting.set("llm_conversation_base_url", "https://llm-conversation.example.com")
      expect(described_class.base_url).to eq("https://llm-conversation.example.com")
    end

    it "dynamically reflects setting changes without caching" do
      Setting.set("llm_conversation_base_url", "https://url1.example.com")
      expect(described_class.base_url).to eq("https://url1.example.com")

      Setting.set("llm_conversation_base_url", "https://url2.example.com")
      expect(described_class.base_url).to eq("https://url2.example.com")
    end

    it "does not cache the value in class instance variables" do
      # Set initial value
      Setting.set("llm_conversation_base_url", "https://initial.example.com")
      described_class.base_url

      # Change the setting
      Setting.set("llm_conversation_base_url", "https://changed.example.com")

      # Verify it doesn't use cached value from @base_url or similar
      expect(described_class.base_url).to eq("https://changed.example.com")

      # Verify no instance variables are being set on the class
      expect(described_class.instance_variables).not_to include(:@base_url)
    end
  end

  describe "#starting_messages" do
    before do
      allow(described_class).to receive(:base_url).and_return("http://localhost:3001")
    end

    let(:create_response) do
      {
        "success" => true,
        "data" => {
          "id" => conversation_id,
          "root_account_id" => root_account_uuid
        }
      }
    end

    let(:add_message_response) do
      {
        "success" => true,
        "data" => {
          "text" => "What do you know about this topic?"
        }
      }
    end

    before do
      stub_request(:post, "http://localhost:3001/conversations")
        .to_return(status: 200, body: create_response.to_json, headers: { "Content-Type" => "application/json" })

      stub_request(:post, "http://localhost:3001/conversations/#{conversation_id}/messages/add")
        .to_return(status: 200, body: add_message_response.to_json, headers: { "Content-Type" => "application/json" })
    end

    it "creates a conversation and returns starting messages" do
      result = client.starting_messages

      expect(result).to be_a(Hash)
      expect(result[:conversation_id]).to eq(conversation_id)
      expect(result[:messages]).to be_an(Array)
      expect(result[:messages].length).to eq(2)
      expect(result[:messages][0][:role]).to eq("User")
      expect(result[:messages][1][:role]).to eq("Assistant")
      expect(result[:messages][1][:text]).to eq("What do you know about this topic?")
    end

    it "raises ConversationError on API failure" do
      stub_request(:post, "http://localhost:3001/conversations")
        .to_return(status: 500, body: "Internal Server Error")

      expect { client.starting_messages }.to raise_error(LlmConversation::Errors::ConversationError)
    end
  end

  describe "#continue_conversation" do
    before do
      allow(described_class).to receive(:base_url).and_return("http://localhost:3001")
    end

    let(:messages) do
      [
        { role: "User", text: "Initial message" },
        { role: "Assistant", text: "Initial response" }
      ]
    end

    let(:add_message_response) do
      {
        "success" => true,
        "data" => {
          "text" => "Follow-up response"
        }
      }
    end

    before do
      stub_request(:post, "http://localhost:3001/conversations/#{conversation_id}/messages/add")
        .to_return(status: 200, body: add_message_response.to_json, headers: { "Content-Type" => "application/json" })
    end

    it "adds user message and returns updated messages" do
      result = client_with_conversation_id.continue_conversation(
        messages:,
        new_user_message: "Follow-up question"
      )

      expect(result).to be_a(Hash)
      expect(result[:conversation_id]).to eq(conversation_id)
      expect(result[:messages].length).to eq(4)
      expect(result[:messages][-2][:role]).to eq("User")
      expect(result[:messages][-2][:text]).to eq("Follow-up question")
      expect(result[:messages][-1][:role]).to eq("Assistant")
      expect(result[:messages][-1][:text]).to eq("Follow-up response")
    end

    it "raises ConversationError on API failure" do
      stub_request(:post, "http://localhost:3001/conversations/#{conversation_id}/messages/add")
        .to_return(status: 500, body: "Internal Server Error")

      expect do
        client_with_conversation_id.continue_conversation(
          messages:,
          new_user_message: "Follow-up question"
        )
      end.to raise_error(LlmConversation::Errors::ConversationError)
    end
  end

  describe "#messages" do
    before do
      allow(described_class).to receive(:base_url).and_return("http://localhost:3001")
    end

    let(:messages_response) do
      {
        "success" => true,
        "data" => [
          {
            "id" => "msg1",
            "text" => "User message",
            "is_llm_message" => false
          },
          {
            "id" => "msg2",
            "text" => "Assistant message",
            "is_llm_message" => true
          }
        ]
      }
    end

    before do
      stub_request(:get, "http://localhost:3001/conversations/#{conversation_id}/messages")
        .to_return(status: 200, body: messages_response.to_json, headers: { "Content-Type" => "application/json" })
    end

    it "fetches and converts messages" do
      result = client_with_conversation_id.messages

      expect(result).to be_an(Array)
      expect(result.length).to eq(2)
      expect(result[0][:role]).to eq("User")
      expect(result[0][:text]).to eq("User message")
      expect(result[1][:role]).to eq("Assistant")
      expect(result[1][:text]).to eq("Assistant message")
    end

    it "raises ConversationError when conversation_id is not set" do
      expect { client.messages }.to raise_error(LlmConversation::Errors::ConversationError, /Conversation ID not set/)
    end

    it "raises ConversationError on API failure" do
      stub_request(:get, "http://localhost:3001/conversations/#{conversation_id}/messages")
        .to_return(status: 404, body: "Not Found")

      expect { client_with_conversation_id.messages }.to raise_error(LlmConversation::Errors::ConversationError)
    end
  end
end
