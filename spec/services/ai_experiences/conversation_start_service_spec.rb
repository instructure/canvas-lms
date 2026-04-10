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

describe AiExperiences::ConversationStartService do
  let(:user) { user_model }
  let(:root_account_uuid) { "test-account-uuid" }
  let(:facts) { "Test facts" }
  let(:learning_objectives) { "Test learning objectives" }
  let(:scenario) { "Test scenario" }
  let(:conversation_id) { "test-conversation-id" }
  let(:http_client) { instance_double(LlmConversation::HttpClient) }
  let(:service) { described_class.new }
  let(:create_response) do
    {
      "success" => true,
      "data" => {
        "id" => conversation_id,
        "root_account_id" => root_account_uuid
      }
    }
  end
  let(:messages_response) do
    {
      "success" => true,
      "data" => [
        { "id" => "msg1", "text" => "Hello! I'm ready to help you learn.", "is_llm_message" => false },
        { "id" => "msg2", "text" => "What do you know about this topic?", "is_llm_message" => true }
      ]
    }
  end

  before do
    allow(LlmConversation::HttpClient).to receive(:new).and_return(http_client)
  end

  describe "#start" do
    before do
      allow(http_client).to receive(:post)
        .with("/conversations", payload: hash_including(
          prompt_code: "alpha",
          auto_initialize: true,
          variables: { scenario:, facts:, learning_objectives: }
        ))
        .and_return(create_response)

      allow(http_client).to receive(:get)
        .with("/conversations/#{conversation_id}/messages")
        .and_return(messages_response)
    end

    it "creates a conversation and returns starting messages" do
      result = service.start(
        current_user: user,
        root_account_uuid:,
        facts:,
        learning_objectives:,
        scenario:
      )

      expect(result[:conversation_id]).to eq(conversation_id)
      expect(result[:messages]).to be_an(Array)
      expect(result[:messages].length).to eq(2)
      expect(result[:messages][0][:role]).to eq("User")
      expect(result[:messages][1][:role]).to eq("Assistant")
      expect(result[:messages][1][:text]).to eq("What do you know about this topic?")
    end

    it "sends conversation_context_id instead of variables when provided" do
      allow(http_client).to receive(:post)
        .with("/conversations", payload: hash_including(conversation_context_id: "ctx-id"))
        .and_return(create_response)

      result = service.start(
        current_user: user,
        root_account_uuid:,
        conversation_context_id: "ctx-id"
      )

      expect(result[:conversation_id]).to eq(conversation_id)
      expect(result[:messages].length).to eq(2)
    end

    it "raises ConversationError on API failure" do
      allow(http_client).to receive(:post)
        .and_raise(LlmConversation::Errors::ConversationError, "Service unavailable")

      expect do
        service.start(current_user: user, root_account_uuid:, facts:, learning_objectives:, scenario:)
      end.to raise_error(LlmConversation::Errors::ConversationError)
    end

    it "raises ConversationError when messages fetch fails" do
      allow(http_client).to receive(:get)
        .and_raise(LlmConversation::Errors::ConversationError, "Failed to get messages")

      expect do
        service.start(current_user: user, root_account_uuid:, facts:, learning_objectives:, scenario:)
      end.to raise_error(LlmConversation::Errors::ConversationError)
    end
  end
end
