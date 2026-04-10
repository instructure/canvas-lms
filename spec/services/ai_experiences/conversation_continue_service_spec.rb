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

describe AiExperiences::ConversationContinueService do
  let(:user) { user_model }
  let(:conversation_id) { "test-conversation-id" }
  let(:http_client) { instance_double(LlmConversation::HttpClient) }
  let(:service) { described_class.new }
  let(:add_message_response) do
    {
      "success" => true,
      "data" => { "text" => "Follow-up response" }
    }
  end
  let(:refreshed_messages_response) do
    {
      "success" => true,
      "data" => [
        { "id" => "msg1", "text" => "Initial message", "is_llm_message" => false, "feedback" => [] },
        { "id" => "msg2", "text" => "Initial response", "is_llm_message" => true, "feedback" => [] },
        { "id" => "msg3", "text" => "Follow-up question", "is_llm_message" => false, "feedback" => [] },
        { "id" => "msg4", "text" => "Follow-up response", "is_llm_message" => true, "feedback" => [] }
      ]
    }
  end

  before do
    allow(LlmConversation::HttpClient).to receive(:new).and_return(http_client)
  end

  describe "#continue" do
    before do
      allow(http_client).to receive(:post)
        .with("/conversations/#{conversation_id}/messages/add", payload: hash_including(role: "User", text: "Follow-up question"))
        .and_return(add_message_response)

      allow(http_client).to receive(:get)
        .with(%r{/conversations/#{conversation_id}/messages\?include_feedback_from=})
        .and_return(refreshed_messages_response)
    end

    it "sends the message and returns updated messages" do
      result = service.continue(
        conversation_id:,
        new_user_message: "Follow-up question",
        requesting_user: user
      )

      expect(result[:conversation_id]).to eq(conversation_id)
      expect(result[:messages].length).to eq(4)
      expect(result[:messages][-2][:role]).to eq("User")
      expect(result[:messages][-2][:text]).to eq("Follow-up question")
      expect(result[:messages][-1][:role]).to eq("Assistant")
      expect(result[:messages][-1][:text]).to eq("Follow-up response")
    end

    it "raises ConversationError when conversation_id is not set" do
      expect { service.continue(conversation_id: nil, new_user_message: "Hello") }
        .to raise_error(LlmConversation::Errors::ConversationError, /Conversation ID not set/)
    end

    it "raises ConversationError on API failure" do
      allow(http_client).to receive(:post)
        .and_raise(LlmConversation::Errors::ConversationError, "Failed to send")

      expect { service.continue(conversation_id:, new_user_message: "Hello", requesting_user: user) }
        .to raise_error(LlmConversation::Errors::ConversationError)
    end
  end
end
