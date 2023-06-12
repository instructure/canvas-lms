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

describe Mutations::DeleteConversations do
  let(:sender) { user_model }
  let(:conv) { conversation(sender, user_model).conversation }

  def execute_with_input(delete_input, user_executing: sender)
    mutation_command = <<~GQL
      mutation {
        deleteConversations(input: {
          #{delete_input}
        }) {
          conversationIds
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

  it "removes all messages from the participant's view" do
    query = <<~GQL
      ids: [#{conv.id}]
    GQL
    expect(sender.all_conversations.find_by(conversation: conv).messages.length).to eq 1
    result = execute_with_input(query)
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "deleteConversations", "errors")).to be_nil
    expect(result.dig("data", "deleteConversations", "conversationIds")).to match_array %W[#{conv.id}]
    expect(sender.all_conversations.find_by(conversation: conv).messages.length).to eq 0
  end

  context "errors" do
    def expect_error(result, message)
      errors = result["errors"] || result.dig("data", "deleteConversations", "errors")
      expect(errors).not_to be_nil
      expect(errors[0]["message"]).to match(/#{message}/)
    end

    it "fails if the conversation doesn't exist" do
      query = <<~GQL
        ids: [#{Conversation.maximum(:id)&.next || 0}]
      GQL
      result = execute_with_input(query)
      expect_error(result, "Unable to find Conversation")
    end

    it "fails if the requesting user is not a participant" do
      query = <<~GQL
        ids: [#{conv.id}]
      GQL
      result = execute_with_input(query, user_executing: user_model)
      expect_error(result, "Insufficient permissions")
    end
  end

  context "batching" do
    context "all ids are valid" do
      let(:conv2) { conversation(sender, user_model).conversation }

      it "removes messages from each view" do
        query = <<~GQL
          ids: [#{conv.id}, #{conv2.id}]
        GQL
        expect(sender.all_conversations.find_by(conversation: conv).messages.length).to eq 1
        expect(sender.all_conversations.find_by(conversation: conv2).messages.length).to eq 1
        result = execute_with_input(query)
        expect(result["errors"]).to be_nil
        expect(result.dig("data", "deleteConversations", "errors")).to be_nil
        expect(result.dig("data", "deleteConversations", "conversationIds")).to match_array %W[#{conv.id} #{conv2.id}]
        expect(sender.all_conversations.find_by(conversation: conv).messages.length).to eq 0
        expect(sender.all_conversations.find_by(conversation: conv2).messages.length).to eq 0
      end
    end

    context "some ids are invalid" do
      let(:another_conv) { conversation(user_model, user_model).conversation }
      let(:invalid_id) { Conversation.maximum(:id)&.next || 0 }

      def expect_error(result, id, message)
        errors = result["errors"] || result.dig("data", "deleteConversations", "errors")
        expect(errors).not_to be_nil
        error = errors.find { |i| i["attribute"] == id.to_s }
        expect(error["message"]).to match(/#{message}/)
      end

      it "handles valid data and errors on invalid" do
        query = <<~GQL
          ids: [#{conv.id}, #{another_conv.id}, #{invalid_id}]
        GQL
        expect(sender.all_conversations.find_by(conversation: conv).messages.length).to eq 1
        result = execute_with_input(query)
        expect_error(result, another_conv.id, "Insufficient permissions")
        expect_error(result, invalid_id, "Unable to find Conversation")
        expect(result.dig("data", "deleteConversations", "conversationIds")).to match_array %W[#{conv.id}]
        expect(sender.all_conversations.find_by(conversation: conv).messages.length).to eq 0
      end
    end
  end
end
