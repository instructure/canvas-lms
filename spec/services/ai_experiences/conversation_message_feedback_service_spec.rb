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

describe AiExperiences::ConversationMessageFeedbackService do
  let(:account) { account_model }
  let(:conversation_id) { "test-conversation-id" }
  let(:http_client) { instance_double(LlmConversation::HttpClient) }
  let(:service) { described_class.new(account:) }
  let(:feedback_response) do
    {
      "success" => true,
      "data" => {
        "id" => "fb-1",
        "vote" => "liked",
        "user_id" => "user-uuid",
        "feedback_message" => nil
      }
    }
  end

  before do
    allow(LlmConversation::HttpClient).to receive(:new).and_return(http_client)
  end

  describe "#create" do
    it "posts feedback and returns response data" do
      allow(http_client).to receive(:post)
        .with("/conversations/#{conversation_id}/messages/msg-1/feedback", payload: { user_id: "user-uuid", vote: "liked" })
        .and_return(feedback_response)

      result = service.create(conversation_id:, message_id: "msg-1", user_id: "user-uuid", vote: "liked")

      expect(result["id"]).to eq("fb-1")
      expect(result["vote"]).to eq("liked")
    end

    it "includes feedback_message in payload when provided" do
      allow(http_client).to receive(:post)
        .with("/conversations/#{conversation_id}/messages/msg-1/feedback", payload: { user_id: "user-uuid", vote: "disliked", feedback_message: "Incorrect response" })
        .and_return(feedback_response)

      result = service.create(conversation_id:, message_id: "msg-1", user_id: "user-uuid", vote: "disliked", feedback_message: "Incorrect response")

      expect(result).to be_a(Hash)
    end

    it "raises ConversationError when conversation_id is not set" do
      expect { service.create(conversation_id: nil, message_id: "msg-1", user_id: "user-uuid", vote: "liked") }
        .to raise_error(LlmConversation::Errors::ConversationError, /Conversation ID not set/)
    end

    it "raises ConversationError on API failure" do
      allow(http_client).to receive(:post)
        .and_raise(LlmConversation::Errors::ConversationError, "Internal Server Error")

      expect { service.create(conversation_id:, message_id: "msg-1", user_id: "user-uuid", vote: "liked") }
        .to raise_error(LlmConversation::Errors::ConversationError)
    end
  end

  describe "#update" do
    it "patches feedback and returns response data" do
      allow(http_client).to receive(:patch)
        .with("/conversations/#{conversation_id}/messages/msg-1/feedback/fb-1", payload: { vote: "disliked" })
        .and_return(feedback_response)

      result = service.update(conversation_id:, message_id: "msg-1", feedback_id: "fb-1", vote: "disliked")

      expect(result).to be_a(Hash)
    end

    it "raises ConversationError when conversation_id is not set" do
      expect { service.update(conversation_id: nil, message_id: "msg-1", feedback_id: "fb-1", vote: "liked") }
        .to raise_error(LlmConversation::Errors::ConversationError, /Conversation ID not set/)
    end

    it "raises ConversationError on API failure" do
      allow(http_client).to receive(:patch)
        .and_raise(LlmConversation::Errors::ConversationError, "Internal Server Error")

      expect { service.update(conversation_id:, message_id: "msg-1", feedback_id: "fb-1", vote: "liked") }
        .to raise_error(LlmConversation::Errors::ConversationError)
    end
  end

  describe "#delete" do
    it "sends a DELETE request for the specified feedback" do
      allow(http_client).to receive(:delete)
        .with("/conversations/#{conversation_id}/messages/msg-1/feedback/fb-1")
        .and_return({ "success" => true })

      expect { service.delete(conversation_id:, message_id: "msg-1", feedback_id: "fb-1") }.not_to raise_error
    end

    it "raises ConversationError when conversation_id is not set" do
      expect { service.delete(conversation_id: nil, message_id: "msg-1", feedback_id: "fb-1") }
        .to raise_error(LlmConversation::Errors::ConversationError, /Conversation ID not set/)
    end

    it "raises ConversationError on API failure" do
      allow(http_client).to receive(:delete)
        .and_raise(LlmConversation::Errors::ConversationError, "Not Found")

      expect { service.delete(conversation_id:, message_id: "msg-1", feedback_id: "fb-1") }
        .to raise_error(LlmConversation::Errors::ConversationError)
    end
  end
end
