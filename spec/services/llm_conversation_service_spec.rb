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

require "spec_helper"

RSpec.describe LLMConversationService, type: :service do
  let(:current_user) { User.create!(name: "Test Student") }
  let(:root_account_uuid) { "test-root-uuid" }
  let(:facts) { "The mitochondria is the powerhouse of the cell" }
  let(:learning_objectives) { "Understand cellular biology" }
  let(:scenario) { "You are studying for a biology exam" }

  let(:service) do
    described_class.new(
      current_user:,
      root_account_uuid:,
      facts:,
      learning_objectives:,
      scenario:
    )
  end

  before do
    stub_const("CedarClient", Class.new do
      def self.conversation(*)
        Struct.new(:response, keyword_init: true).new(response: "Hello! Let me help you with your assignment.")
      end
    end)
  end

  describe "#build_input_text" do
    it "interpolates facts, learning objectives, and scenario" do
      result = service.build_input_text

      expect(result).to include(facts)
      expect(result).to include(learning_objectives)
      expect(result).to include(scenario)
    end
  end

  describe "#starting_messages" do
    it "returns an array with user and assistant messages" do
      messages = service.starting_messages

      expect(messages).to be_an(Array)
      expect(messages.length).to eq(2)
      expect(messages[0][:role]).to eq("User")
      expect(messages[1][:role]).to eq("Assistant")
    end

    it "calls CedarClient.conversation with correct parameters" do
      allow(CedarClient).to receive(:conversation).and_call_original

      service.starting_messages

      expect(CedarClient).to have_received(:conversation).with(
        system_prompt: LLMConversationService::SYSTEM_PROMPT,
        messages: array_including(hash_including(role: "User")),
        feature_slug: "ai-experiences-conversation",
        root_account_uuid:,
        current_user:
      )
    end

    it "includes the built input text in the first message" do
      messages = service.starting_messages

      expect(messages[0][:text]).to include(facts)
      expect(messages[0][:text]).to include(learning_objectives)
      expect(messages[0][:text]).to include(scenario)
    end

    it "includes the LLM response in the second message" do
      messages = service.starting_messages

      expect(messages[1][:text]).to eq("Hello! Let me help you with your assignment.")
    end
  end

  describe "#continue_conversation" do
    let(:existing_messages) do
      [
        { role: "User", text: "Initial message" },
        { role: "Assistant", text: "Initial response" }
      ]
    end
    let(:new_user_message) { "Can you explain more?" }

    it "appends new user message and assistant response" do
      messages = service.continue_conversation(
        messages: existing_messages,
        new_user_message:
      )

      expect(messages.length).to eq(4)
      expect(messages[2][:role]).to eq("User")
      expect(messages[2][:text]).to eq(new_user_message)
      expect(messages[3][:role]).to eq("Assistant")
    end

    it "calls CedarClient.conversation with full message history" do
      allow(CedarClient).to receive(:conversation).and_call_original

      service.continue_conversation(
        messages: existing_messages,
        new_user_message:
      )

      expect(CedarClient).to have_received(:conversation).with(
        system_prompt: LLMConversationService::SYSTEM_PROMPT,
        messages: array_including(
          { role: "User", text: "Initial message" },
          { role: "Assistant", text: "Initial response" },
          { role: "User", text: new_user_message }
        ),
        feature_slug: "ai-experiences-conversation",
        root_account_uuid:,
        current_user:
      )
    end

    it "returns the updated messages array" do
      messages = service.continue_conversation(
        messages: existing_messages,
        new_user_message:
      )

      expect(messages).to be_an(Array)
      expect(messages.last[:role]).to eq("Assistant")
      expect(messages.last[:text]).to eq("Hello! Let me help you with your assignment.")
    end
  end

  describe "#new_llm_message" do
    let(:messages) do
      [{ role: "User", text: "Test message" }]
    end

    it "calls CedarClient.conversation and returns response" do
      result = service.new_llm_message(messages:)

      expect(result).to eq("Hello! Let me help you with your assignment.")
    end

    it "passes system prompt to CedarClient" do
      allow(CedarClient).to receive(:conversation).and_call_original

      service.new_llm_message(messages:)

      expect(CedarClient).to have_received(:conversation).with(
        hash_including(system_prompt: LLMConversationService::SYSTEM_PROMPT)
      )
    end

    it "raises ConversationError when CedarClient fails" do
      stub_const("CedarClient", Class.new do
        def self.conversation(*)
          raise StandardError, "API error"
        end
      end)

      expect do
        service.new_llm_message(messages:)
      end.to raise_error(CedarAi::Errors::ConversationError, /Failed to get LLM response: API error/)
    end
  end
end
