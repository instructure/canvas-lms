# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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
describe Mutations::CreateDiscussionTopic do
  before(:once) do
    course_with_teacher(active_all: true)
  end

  def execute_with_input(create_input, current_user = @teacher)
    mutation_command = <<~GQL
      mutation {
        createDiscussionTopic(input: {
          #{create_input}
        }){
          discussionTopic {
            _id
            contextType
            title
            message
            published
            requireInitialPost
          }
          errors {
            attribute
            message
          }
        }
      }
    GQL
    context = { current_user:, request: ActionDispatch::TestRequest.create }
    CanvasSchema.execute(mutation_command, context:)
  end

  it "successfully creates the discussion topic" do
    context_type = "Course"
    title = "Test Title"
    message = "A message"
    published = false
    require_initial_post = true

    query = <<~GQL
      contextId: "#{@course.id}"
      contextType: "#{context_type}"
      title: "#{title}"
      message: "#{message}"
      published: #{published}
      requireInitialPost: #{require_initial_post}
    GQL

    result = execute_with_input(query)
    created_discussion_topic = result.dig("data", "createDiscussionTopic", "discussionTopic")

    expect(result["errors"]).to be_nil
    expect(result.dig("data", "discussionTopic", "errors")).to be_nil

    expect(created_discussion_topic["contextType"]).to eq context_type
    expect(created_discussion_topic["title"]).to eq title
    expect(created_discussion_topic["message"]).to eq message
    expect(created_discussion_topic["published"]).to eq published
    expect(created_discussion_topic["requireInitialPost"]).to be true
    expect(DiscussionTopic.where("id = #{created_discussion_topic["_id"]}").count).to eq 1
  end

  context "errors" do
    def expect_error(result, message)
      errors = result["errors"] || result.dig("data", "createDiscussionTopic", "errors")
      expect(errors).not_to be_nil
      expect(errors[0]["message"]).to match(/#{message}/)
    end

    describe "invalid context" do
      it "returns 'not found' with an incorrect ID" do
        query = <<~GQL
          contextId: "1"
          contextType: "Course"
        GQL
        result = execute_with_input(query)
        expect_error(result, "Not found")
      end

      it "returns 'invalid context' with an incorrect context type" do
        query = <<~GQL
          contextId: "1"
          contextType: "NotAContextType"
        GQL
        result = execute_with_input(query)
        expect_error(result, "Invalid context type")
      end
    end
  end
end
