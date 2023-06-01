# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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
require_relative "../graphql_spec_helper"

describe Mutations::DeleteConversationMessages do
  let(:sender) { user_model }
  let(:conv) { conversation(sender, user_model).conversation }
  let(:message) { ConversationMessage.find_by(conversation: conv, author: sender) }

  def execute_with_input(delete_input, user_executing: sender)
    mutation_command = <<~GQL
      mutation {
        deleteConversationMessages(input: {
          #{delete_input}
        }) {
          conversationMessageIds
          errors {
            attribute
            message
          }
        }
      }
    GQL
    context = { current_user: user_executing, request: ActionDispatch::TestRequest.create }
    CanvasSchema.execute(mutation_command, context:)
  end

  def expect_error(result, message)
    errors = result["errors"] || result.dig("data", "deleteConversationMessages", "errors")
    expect(errors).not_to be_nil
    expect(errors[0]["message"]).to match(/#{message}/)
  end

  it "removes the message from the participant's view" do
    message.root_account_ids = [sender.account.id]
    query = <<~GQL
      ids: [#{message.id}]
    GQL
    expect(sender.all_conversations.find_by(conversation: message.conversation).messages.length).to eq 1
    result = execute_with_input(query)
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "deleteConversationMessages", "errors")).to be_nil
    expect(result.dig("data", "deleteConversationMessages", "conversationMessageIds")).to match_array %W[#{message.id}]
    expect(sender.all_conversations.find_by(conversation: message.conversation).messages.length).to eq 0
  end

  context "errors" do
    it "fails if the message doesn't exist" do
      query = <<~GQL
        ids: [#{ConversationMessage.maximum(:id)&.next || 0}]
      GQL
      result = execute_with_input(query)
      expect_error(result, "Unable to find ConversationMessage")
    end

    it "fails if the requesting user is not a participant" do
      query = <<~GQL
        ids: [#{message.id}]
      GQL
      result = execute_with_input(query, user_executing: user_model)
      expect_error(result, "Insufficient permissions")
    end
  end

  context "batching" do
    context "all ids are valid" do
      let(:message2) { ConversationParticipant.find_by(user: sender, conversation: conv).add_message("test") }

      it "removes messages from the view" do
        message.root_account_ids = [sender.account.id]
        message2.root_account_ids = [sender.account.id]
        query = <<~GQL
          ids: [#{message.id}, #{message2.id}]
        GQL
        expect(sender.all_conversations.find_by(conversation: message.conversation).messages.length).to eq 2
        result = execute_with_input(query)
        expect(result["errors"]).to be_nil
        expect(result.dig("data", "deleteConversationMessages", "errors")).to be_nil
        expect(result.dig("data", "deleteConversationMessages", "conversationMessageIds")).to match_array %W[#{message.id} #{message2.id}]
        expect(sender.all_conversations.find_by(conversation: message.conversation).messages.length).to eq 0
      end
    end

    context "one id doesn't exist" do
      let(:invalid_id) { ConversationMessage.maximum(:id)&.next || 0 }

      it "bails without deleting any messages" do
        query = <<~GQL
          ids: [#{message.id}, #{invalid_id}]
        GQL
        expect(sender.all_conversations.find_by(conversation: message.conversation).messages.length).to eq 1
        result = execute_with_input(query)
        expect_error(result, "Unable to find ConversationMessage")
        expect(result.dig("data", "deleteConversationMessages", "conversationMessageIds")).to be_nil
        expect(sender.all_conversations.find_by(conversation: message.conversation).messages.length).to eq 1
      end
    end

    context "ids are part of different conversations" do
      let(:conv2) { conversation(sender, user_model).conversation }
      let(:message2) { ConversationMessage.find_by(conversation: conv2, author: sender) }

      it "bails without deleting any messages" do
        query = <<~GQL
          ids: [#{message.id}, #{message2.id}]
        GQL
        expect(sender.all_conversations.find_by(conversation: message.conversation).messages.length).to eq 1
        expect(sender.all_conversations.find_by(conversation: message2.conversation).messages.length).to eq 1
        result = execute_with_input(query)
        expect_error(result, "All ConversationMessages must exist within the same Conversation")
        expect(result.dig("data", "deleteConversationMessages", "conversationMessageIds")).to be_nil
        expect(sender.all_conversations.find_by(conversation: message.conversation).messages.length).to eq 1
        expect(sender.all_conversations.find_by(conversation: message2.conversation).messages.length).to eq 1
      end
    end
  end
end
