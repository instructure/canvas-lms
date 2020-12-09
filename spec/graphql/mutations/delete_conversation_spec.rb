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

describe Mutations::DeleteConversation do
  before :once do
    @sender = user_model
    @conversation = conversation(@sender, user_model).conversation
  end

  def execute_with_input(delete_input, user_executing: @sender)
    mutation_command = <<~GQL
      mutation {
        deleteConversation(input: {
          #{delete_input}
        }) {
          conversationId
          errors {
            attribute
            message
          }
        }
      }
    GQL
    context = {current_user: user_executing, request: ActionDispatch::TestRequest.create}
    CanvasSchema.execute(mutation_command, context: context)
  end

  it "removes all messages from the participant's view" do
    query = <<~QUERY
      id: #{@conversation.id}
    QUERY
    expect(@sender.all_conversations.find_by(conversation: @conversation).messages.length).to eq 1
    result = execute_with_input(query)
    expect(result.dig('errors')).to be_nil
    expect(result.dig('data', 'deleteConversation', 'errors')).to be_nil
    expect(result.dig('data', 'deleteConversation', 'conversationId')).to eq @conversation.id.to_s
    expect(@sender.all_conversations.find_by(conversation: @conversation).messages.length).to eq 0
  end

  context "errors" do
    def expect_error(result, message)
      errors = result.dig('errors') || result.dig('data', 'deleteConversation', 'errors')
      expect(errors).not_to be_nil
      expect(errors[0]['message']).to match(/#{message}/)
    end

    it "fails if the conversation doesn't exist" do
      query = <<~QUERY
        id: #{Conversation.maximum(:id).next}
      QUERY
      result = execute_with_input(query)
      expect_error(result, 'Unable to find Conversation')
    end

    it "fails if the requesting user is not a participant" do
      query = <<~QUERY
        id: #{@conversation.id}
      QUERY
      result = execute_with_input(query, user_executing: user_model)
      expect_error(result, 'insufficient permissions')
    end
  end
end