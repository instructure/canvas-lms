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

require_relative "../graphql_spec_helper"

describe Mutations::UpdateConversationParticipants do
  let(:sender) { user_model }
  let(:conv) { conversation(sender, user_model, user_model).conversation }

  def execute_with_input(update_input, user_executing: sender)
    mutation_command = <<~GQL
      mutation {
        updateConversationParticipants(input: {
          #{update_input}
        }) {
          conversationParticipants {
            label
            workflowState
            subscribed
          }
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

  it "updates the requesting user's participation record" do
    query = <<~GQL
      conversationIds: [#{conv.id}],
      starred: true,
      subscribed: false,
      workflowState: "archived"
    GQL
    participant = sender.all_conversations.find_by(conversation: conv)
    expect(participant).to be_subscribed
    expect(participant).to be_read
    expect(participant.starred).to be_falsey

    result = execute_with_input(query)
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateConversationParticipants", "errors")).to be_nil
    updated_attributes = result.dig("data", "updateConversationParticipants", "conversationParticipants")
    expect(updated_attributes).to include({
                                            "subscribed" => false,
                                            "workflowState" => "archived",
                                            "label" => "starred"
                                          })

    participant = participant.reload
    expect(participant).not_to be_subscribed
    expect(participant).to be_archived
    expect(participant.starred).to be_truthy
  end

  describe "error handling" do
    def expect_error(result, message)
      errors = result["errors"] || result.dig("data", "updateConversationParticipants", "errors")
      expect(errors).not_to be_nil
      expect(errors[0]["message"]).to match(/#{message}/)
    end

    it "fails if the conversation doesn't exist" do
      query = <<~GQL
        conversationIds: [#{Conversation.maximum(:id)&.next || 0}]
      GQL
      result = execute_with_input(query)
      expect_error(result, "Unable to find Conversation")
    end

    it "fails if the requesting user is not a participant" do
      query = <<~GQL
        conversationIds: [#{conv.id}]
      GQL
      result = execute_with_input(query, user_executing: user_model)
      expect_error(result, "Insufficient permissions")
    end
  end

  context "batching" do
    context "all ids are valid" do
      let(:conv2) { conversation(sender, user_model).conversation }

      it "updates each view" do
        allow(InstStatsd::Statsd).to receive(:count)
        query = <<~GQL
          conversationIds: [#{conv.id}, #{conv2.id}],
          starred: true
        GQL
        participant1 = sender.all_conversations.find_by(conversation: conv)
        expect(participant1.starred).to be_falsey
        participant2 = sender.all_conversations.find_by(conversation: conv2)
        expect(participant2.starred).to be_falsey

        result = execute_with_input(query)
        expect(result["errors"]).to be_nil
        expect(result.dig("data", "updateConversationParticipants", "errors")).to be_nil
        updated_attrs = result.dig("data", "updateConversationParticipants", "conversationParticipants")
        expect(updated_attrs.pluck("label")).to match_array %w[starred starred]

        participant1 = participant1.reload
        expect(participant1.starred).to be_truthy
        participant2 = participant2.reload
        expect(participant2.starred).to be_truthy
        expect(InstStatsd::Statsd).to have_received(:count).with("inbox.conversation.starred.react", 2)
      end

      it "unstars each conversation" do
        allow(InstStatsd::Statsd).to receive(:count)
        query = <<~GQL
          conversationIds: [#{conv.id}, #{conv2.id}],
          starred: false
        GQL

        participant1 = sender.all_conversations.find_by(conversation: conv)
        participant2 = sender.all_conversations.find_by(conversation: conv2)

        result = execute_with_input(query)
        expect(result["errors"]).to be_nil
        expect(result.dig("data", "updateConversationParticipants", "errors")).to be_nil
        updated_attrs = result.dig("data", "updateConversationParticipants", "conversationParticipants")
        expect(updated_attrs.pluck("label")).to match_array [nil, nil]

        participant1 = participant1.reload
        expect(participant1.starred).to be_falsey
        participant2 = participant2.reload
        expect(participant2.starred).to be_falsey
        expect(InstStatsd::Statsd).to have_received(:count).with("inbox.conversation.unstarred.react", 2)
      end

      it "marks each conversation as unread" do
        allow(InstStatsd::Statsd).to receive(:count)
        allow(InstStatsd::Statsd).to receive(:increment)
        query = <<~GQL
          conversationIds: [#{conv.id}, #{conv2.id}],
          workflowState: "unread"
        GQL

        result = execute_with_input(query)
        expect(result["errors"]).to be_nil
        expect(result.dig("data", "updateConversationParticipants", "errors")).to be_nil

        expect(InstStatsd::Statsd).to have_received(:count).with("inbox.conversation.unread.react", 2)
        expect(InstStatsd::Statsd).not_to have_received(:count).with("inbox.conversation.unread.legacy", 2)
        expect(InstStatsd::Statsd).not_to have_received(:increment).with("inbox.conversation.unarchived.react")

        updated_attrs = result.dig("data", "updateConversationParticipants", "conversationParticipants")
        expect(updated_attrs.pluck("workflowState")).to match_array %w[unread unread]
      end

      it "archives each conversation" do
        allow(InstStatsd::Statsd).to receive(:count)
        allow(InstStatsd::Statsd).to receive(:increment)
        query = <<~GQL
          conversationIds: [#{conv.id}, #{conv2.id}],
          workflowState: "archived"
        GQL

        result = execute_with_input(query)
        expect(result["errors"]).to be_nil
        expect(result.dig("data", "updateConversationParticipants", "errors")).to be_nil

        expect(InstStatsd::Statsd).to have_received(:count).with("inbox.conversation.archived.react", 2)
        expect(InstStatsd::Statsd).not_to have_received(:count).with("inbox.conversation.archived.legacy", 2)

        updated_attrs = result.dig("data", "updateConversationParticipants", "conversationParticipants")
        expect(updated_attrs.pluck("workflowState")).to match_array %w[archived archived]
      end

      it "unarchives each conversation by marking as read" do
        allow(InstStatsd::Statsd).to receive(:increment)
        sender.all_conversations.find_by(conversation: conv).update(workflow_state: "archived")
        sender.all_conversations.find_by(conversation: conv2).update(workflow_state: "archived")
        query = <<~GQL
          conversationIds: [#{conv.id}, #{conv2.id}],
          workflowState: "read"
        GQL

        result = execute_with_input(query)
        expect(result["errors"]).to be_nil
        expect(result.dig("data", "updateConversationParticipants", "errors")).to be_nil

        expect(InstStatsd::Statsd).to have_received(:increment).with("inbox.conversation.unarchived.react").twice
        expect(InstStatsd::Statsd).not_to have_received(:increment).with("inbox.conversation.unarchived.legacy")

        updated_attrs = result.dig("data", "updateConversationParticipants", "conversationParticipants")
        expect(updated_attrs.pluck("workflowState")).to match_array %w[read read]
      end

      it "unarchives each conversation by marking as unread" do
        allow(InstStatsd::Statsd).to receive(:increment)
        sender.all_conversations.find_by(conversation: conv).update(workflow_state: "archived")
        sender.all_conversations.find_by(conversation: conv2).update(workflow_state: "archived")
        query = <<~GQL
          conversationIds: [#{conv.id}, #{conv2.id}],
          workflowState: "unread"
        GQL

        result = execute_with_input(query)
        expect(result["errors"]).to be_nil
        expect(result.dig("data", "updateConversationParticipants", "errors")).to be_nil

        expect(InstStatsd::Statsd).to have_received(:increment).with("inbox.conversation.unarchived.react").twice
        expect(InstStatsd::Statsd).not_to have_received(:increment).with("inbox.conversation.unarchived.legacy")

        updated_attrs = result.dig("data", "updateConversationParticipants", "conversationParticipants")
        expect(updated_attrs.pluck("workflowState")).to match_array %w[unread unread]
      end
    end

    context "some ids are invalid" do
      let(:another_conv) { conversation(user_model, user_model).conversation }
      let(:invalid_id) { Conversation.maximum(:id)&.next || 0 }

      def expect_error(result, id, message)
        errors = result["errors"] || result.dig("data", "updateConversationParticipants", "errors")
        expect(errors).not_to be_nil
        error = errors.find { |i| i["attribute"] == id.to_s }
        expect(error["message"]).to match(/#{message}/)
      end

      it "handles valid data and errors on invalid" do
        query = <<~GQL
          conversationIds: [#{conv.id}, #{another_conv.id}, #{invalid_id}],
          starred: true
        GQL
        participant = sender.all_conversations.find_by(conversation: conv)
        expect(participant.starred).to be_falsey

        result = execute_with_input(query)
        expect_error(result, another_conv.id, "Insufficient permissions")
        expect_error(result, invalid_id, "Unable to find Conversation")
        updated_attributes = result.dig("data", "updateConversationParticipants", "conversationParticipants")
        expect(updated_attributes).to include({
                                                "subscribed" => true,
                                                "workflowState" => "read",
                                                "label" => "starred"
                                              })

        participant = participant.reload
        expect(participant.starred).to be_truthy
      end
    end
  end
end
