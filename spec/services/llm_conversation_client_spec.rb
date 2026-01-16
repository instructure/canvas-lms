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

    context "with region-specific settings" do
      before do
        allow(ApplicationController).to receive_messages(region: "us-east-1", test_cluster_name: nil)
      end

      after do
        Setting.remove("llm_conversation_base_url")
        Setting.remove("llm_conversation_base_url_us-east-1")
      end

      it "uses region-specific URL when available" do
        Setting.set("llm_conversation_base_url", "https://default.example.com")
        Setting.set("llm_conversation_base_url_us-east-1", "https://us-east-1.example.com")
        expect(described_class.base_url).to eq("https://us-east-1.example.com")
      end

      it "raises error when neither region-specific nor base URL is set" do
        expect { described_class.base_url }.to raise_error(
          LlmConversation::Errors::ConversationError,
          /Neither llm_conversation_base_url_us-east-1 nor llm_conversation_base_url/
        )
      end
    end

    context "with beta/test cluster settings" do
      before do
        allow(ApplicationController).to receive_messages(region: "us-east-1", test_cluster_name: "beta")
      end

      after do
        Setting.remove("llm_conversation_base_url")
        Setting.remove("llm_conversation_base_url_us-east-1")
        Setting.remove("llm_conversation_base_url_beta_us-east-1")
      end

      it "uses beta-specific URL when available in beta environment" do
        Setting.set("llm_conversation_base_url_beta_us-east-1", "https://beta-us-east-1.example.com")
        Setting.set("llm_conversation_base_url_us-east-1", "https://prod-us-east-1.example.com")
        expect(described_class.base_url).to eq("https://beta-us-east-1.example.com")
      end

      it "raises error when no URLs are configured" do
        expect { described_class.base_url }.to raise_error(
          LlmConversation::Errors::ConversationError,
          /None of llm_conversation_base_url_beta_us-east-1, llm_conversation_base_url_us-east-1, or llm_conversation_base_url/
        )
      end
    end

    context "with test cluster (not beta)" do
      before do
        allow(ApplicationController).to receive_messages(region: "us-west-2", test_cluster_name: "test")
      end

      after do
        Setting.remove("llm_conversation_base_url_us-west-2")
        Setting.remove("llm_conversation_base_url_beta_us-west-2")
      end

      it "uses beta-specific URL for test cluster as well" do
        Setting.set("llm_conversation_base_url_beta_us-west-2", "https://staging-us-west-2.example.com")
        Setting.set("llm_conversation_base_url_us-west-2", "https://prod-us-west-2.example.com")
        expect(described_class.base_url).to eq("https://staging-us-west-2.example.com")
      end
    end

    context "without region" do
      before do
        allow(ApplicationController).to receive_messages(region: nil, test_cluster_name: nil)
      end

      it "uses base URL when no region is available" do
        Setting.set("llm_conversation_base_url", "https://default.example.com")
        expect(described_class.base_url).to eq("https://default.example.com")
      end

      it "raises error when base URL is not configured and no region" do
        expect { described_class.base_url }.to raise_error(
          LlmConversation::Errors::ConversationError,
          "llm_conversation_base_url setting is not configured"
        )
      end
    end
  end

  describe ".bearer_token" do
    it "returns the bearer token from credentials" do
      allow(Rails.application.credentials).to receive(:llm_conversation_bearer_token).and_return("test-bearer-token")
      expect(described_class.bearer_token).to eq("test-bearer-token")
    end

    it "returns nil when token is not configured" do
      allow(Rails.application.credentials).to receive(:llm_conversation_bearer_token).and_return(nil)
      expect(described_class.bearer_token).to be_nil
    end
  end

  describe "#starting_messages" do
    before do
      allow(described_class).to receive_messages(base_url: "http://localhost:3001", bearer_token: "test-bearer-token")
    end

    let(:create_response) do
      {
        "success" => true,
        "data" => {
          "id" => conversation_id,
          "root_account_id" => root_account_uuid,
          "first_message" => "Scenario: Test scenario\n\nFacts: Test facts\nLearning objectives: Test learning objectives\n\nStart the conversation with a focused question (max 15 words)."
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
        .with(
          headers: { "Authorization" => "Bearer test-bearer-token" },
          body: hash_including(
            "prompt_code" => "alpha",
            "auto_initialize" => true,
            "variables" => hash_including(
              "scenario" => scenario,
              "facts" => facts,
              "learning_objectives" => learning_objectives
            )
          )
        )
        .to_return(status: 200, body: create_response.to_json, headers: { "Content-Type" => "application/json" })

      stub_request(:get, "http://localhost:3001/conversations/#{conversation_id}/messages")
        .with(headers: { "Authorization" => "Bearer test-bearer-token" })
        .to_return(status: 200,
                   body: {
                     "success" => true,
                     "data" => [
                       {
                         "id" => "msg1",
                         "text" => "Hello! I'm ready to help you learn.",
                         "is_llm_message" => false
                       },
                       {
                         "id" => "msg2",
                         "text" => "What do you know about this topic?",
                         "is_llm_message" => true
                       }
                     ]
                   }.to_json,
                   headers: { "Content-Type" => "application/json" })
    end

    it "creates a conversation with alpha prompt and returns starting messages" do
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

    it "raises ConversationError when bearer token is not configured" do
      allow(described_class).to receive(:bearer_token).and_return(nil)
      expect { client.starting_messages }.to raise_error(
        LlmConversation::Errors::ConversationError,
        "llm_conversation_bearer_token not found in vault secrets"
      )
    end

    it "raises ConversationError when messages fetch fails after conversation creation" do
      stub_request(:get, "http://localhost:3001/conversations/#{conversation_id}/messages")
        .with(headers: { "Authorization" => "Bearer test-bearer-token" })
        .to_return(status: 500, body: "Internal Server Error")

      expect { client.starting_messages }.to raise_error(
        LlmConversation::Errors::ConversationError,
        /Failed to get messages/
      )
    end

    it "sets the conversation_id after creating conversation" do
      expect(client.instance_variable_get(:@conversation_id)).to be_nil
      client.starting_messages
      expect(client.instance_variable_get(:@conversation_id)).to eq(conversation_id)
    end

    context "with conversation_context_id" do
      let(:client_with_context) do
        described_class.new(
          current_user: user,
          root_account_uuid:,
          facts:,
          learning_objectives:,
          scenario:,
          conversation_context_id: "test-context-id"
        )
      end

      before do
        stub_request(:post, "http://localhost:3001/conversations")
          .with(
            headers: { "Authorization" => "Bearer test-bearer-token" },
            body: hash_including(
              "prompt_code" => "alpha",
              "auto_initialize" => true,
              "conversation_context_id" => "test-context-id"
            )
          )
          .to_return(status: 200, body: create_response.to_json, headers: { "Content-Type" => "application/json" })

        stub_request(:get, "http://localhost:3001/conversations/#{conversation_id}/messages")
          .with(headers: { "Authorization" => "Bearer test-bearer-token" })
          .to_return(status: 200,
                     body: {
                       "success" => true,
                       "data" => [
                         {
                           "id" => "msg1",
                           "text" => "Hello! I'm ready to help you learn.",
                           "is_llm_message" => false
                         },
                         {
                           "id" => "msg2",
                           "text" => "What do you know about this topic?",
                           "is_llm_message" => true
                         }
                       ]
                     }.to_json,
                     headers: { "Content-Type" => "application/json" })
      end

      it "sends conversation_context_id instead of variables" do
        result = client_with_context.starting_messages

        expect(result).to be_a(Hash)
        expect(result[:conversation_id]).to eq(conversation_id)
        expect(result[:messages]).to be_an(Array)
        expect(result[:messages].length).to eq(2)
      end
    end
  end

  describe "#continue_conversation" do
    before do
      allow(described_class).to receive_messages(base_url: "http://localhost:3001", bearer_token: "test-bearer-token")
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
        .with(headers: { "Authorization" => "Bearer test-bearer-token" })
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
      allow(described_class).to receive_messages(base_url: "http://localhost:3001", bearer_token: "test-bearer-token")
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
        .with(headers: { "Authorization" => "Bearer test-bearer-token" })
        .to_return(status: 200, body: messages_response.to_json, headers: { "Content-Type" => "application/json" })
    end

    it "fetches and converts messages" do
      result = client_with_conversation_id.messages

      expect(result).to be_a(Hash)
      expect(result[:messages]).to be_an(Array)
      expect(result[:messages].length).to eq(2)
      expect(result[:messages][0][:role]).to eq("User")
      expect(result[:messages][0][:text]).to eq("User message")
      expect(result[:messages][1][:role]).to eq("Assistant")
      expect(result[:messages][1][:text]).to eq("Assistant message")
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

  describe "#messages_with_conversation_progress" do
    before do
      allow(described_class).to receive_messages(base_url: "http://localhost:3001", bearer_token: "test-bearer-token")
    end

    let(:conversation_response) do
      {
        "success" => true,
        "data" => {
          "id" => conversation_id,
          "learning_objective_progress" => {
            "objectives" => [
              { "objective" => "Learn basics", "status" => "covered" },
              { "objective" => "Advanced topics", "status" => "" }
            ]
          }
        }
      }
    end

    let(:messages_response) do
      {
        "success" => true,
        "data" => [
          {
            "id" => "msg1",
            "text" => "User message",
            "is_llm_message" => false
          }
        ]
      }
    end

    before do
      stub_request(:get, "http://localhost:3001/conversations/#{conversation_id}")
        .with(headers: { "Authorization" => "Bearer test-bearer-token" })
        .to_return(status: 200, body: conversation_response.to_json, headers: { "Content-Type" => "application/json" })

      stub_request(:get, "http://localhost:3001/conversations/#{conversation_id}/messages")
        .with(headers: { "Authorization" => "Bearer test-bearer-token" })
        .to_return(status: 200, body: messages_response.to_json, headers: { "Content-Type" => "application/json" })
    end

    it "fetches messages and progress from conversation endpoint" do
      result = client_with_conversation_id.messages_with_conversation_progress

      expect(result).to be_a(Hash)
      expect(result[:messages]).to be_an(Array)
      expect(result[:progress]).to be_a(Hash)
      expect(result[:progress][:percentage]).to eq(50)
      expect(result[:progress][:current]).to eq(1)
      expect(result[:progress][:total]).to eq(2)
      expect(result[:progress][:objectives]).to be_an(Array)
      expect(result[:progress][:objectives].length).to eq(2)
    end
  end

  describe "#extract_progress_from_data" do
    it "extracts and calculates progress correctly" do
      progress_data = {
        "objectives" => [
          { "objective" => "Objective 1", "status" => "covered" },
          { "objective" => "Objective 2", "status" => "" },
          { "objective" => "Objective 3", "status" => "covered" }
        ]
      }

      result = client.send(:extract_progress_from_data, progress_data)

      expect(result[:current]).to eq(2)
      expect(result[:total]).to eq(3)
      expect(result[:percentage]).to eq(67)
      expect(result[:objectives]).to eq(progress_data["objectives"])
    end

    it "returns nil when progress_data is nil" do
      result = client.send(:extract_progress_from_data, nil)
      expect(result).to be_nil
    end

    it "handles empty objectives array" do
      progress_data = { "objectives" => [] }
      result = client.send(:extract_progress_from_data, progress_data)

      expect(result[:current]).to eq(0)
      expect(result[:total]).to eq(0)
      expect(result[:percentage]).to eq(0)
    end
  end
end
