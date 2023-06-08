# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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
describe Mutations::DeleteDiscussionTopic do
  before(:once) do
    course_with_teacher(active_all: true)
  end

  let(:sender) { @teacher }
  let(:discussion_topic) { @course.discussion_topics.create!(user: sender) }

  def execute_with_input(delete_input, user_executing: sender)
    mutation_command = <<~GQL
      mutation {
        deleteDiscussionTopic(input: {
          #{delete_input}
        }){
          discussionTopicId
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

  it "destroys the discussion entry and returns id" do
    query = <<~GQL
      id: #{discussion_topic.id}
    GQL
    expect(DiscussionTopic.where("user_id = #{sender.id} and deleted_at is null").length).to eq 1
    result = execute_with_input(query)
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "discussionTopicId", "errors")).to be_nil
    expect(result.dig("data", "deleteDiscussionTopic", "discussionTopicId")).to eq discussion_topic.id.to_s
    expect(DiscussionTopic.where("user_id = #{sender.id} and deleted_at is null").count).to eq 0
  end

  context "errors" do
    def expect_error(result, message)
      errors = result["errors"] || result.dig("data", "deleteDiscussionTopic", "errors")
      expect(errors).not_to be_nil
      expect(errors[0]["message"]).to match(/#{message}/)
    end

    it "returns nil if the discussion entry doesn't exist" do
      query = <<~GQL
        id: #{DiscussionTopic.maximum(:id)&.next || 0}
      GQL
      result = execute_with_input(query)
      expect_error(result, "Unable to find Discussion Topic")
    end

    context "user does not have read permissions" do
      it "fails if the requesting user is not the discussion entry user" do
        query = <<~GQL
          id: #{discussion_topic.id}
        GQL
        result = execute_with_input(query, user_executing: user_model)
        expect_error(result, "Unable to find Discussion Topic")
      end
    end

    context "user can read the discussion entry" do
      it "fails with Insufficient permissions if the requesting user is not the discussion entry user" do
        query = <<~GQL
          id: #{discussion_topic.id}
        GQL
        course_with_student(course: @course)
        result = execute_with_input(query, user_executing: @student)
        expect_error(result, "Insufficient permissions")
      end
    end
  end
end
