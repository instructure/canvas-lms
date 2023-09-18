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
            anonymousState
            isAnonymousAuthor
            delayedPostAt
            lockAt
            allowRating
            onlyGradersCanRate
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
      anonymousState: "off"
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
    expect(created_discussion_topic["anonymousState"]).to be_nil
    expect(created_discussion_topic["allowRating"]).to be false
    expect(created_discussion_topic["onlyGradersCanRate"]).to be false
    expect(DiscussionTopic.where("id = #{created_discussion_topic["_id"]}").count).to eq 1
  end

  it "creates an allow_rating discussion topic" do
    query = <<~GQL
      contextId: "#{@course.id}"
      contextType: "Course"
      title: "Allows Ratings"
      message: "You can like this"
      allowRating: true
      published: true
    GQL

    result = execute_with_input(query)
    created_discussion_topic = result.dig("data", "createDiscussionTopic", "discussionTopic")

    expect(result["errors"]).to be_nil
    expect(result.dig("data", "discussionTopic", "errors")).to be_nil
    expect(created_discussion_topic["allowRating"]).to be true
    expect(created_discussion_topic["onlyGradersCanRate"]).to be false
  end

  it "creates an only_graders_can_rate discussion topic" do
    query = <<~GQL
      contextId: "#{@course.id}"
      contextType: "Course"
      title: "Allows Ratings"
      message: "You can like this"
      allowRating: true
      onlyGradersCanRate: true
      published: true
    GQL

    result = execute_with_input(query)
    created_discussion_topic = result.dig("data", "createDiscussionTopic", "discussionTopic")

    expect(result["errors"]).to be_nil
    expect(result.dig("data", "discussionTopic", "errors")).to be_nil
    expect(created_discussion_topic["allowRating"]).to be true
    expect(created_discussion_topic["onlyGradersCanRate"]).to be true
  end

  it "creates a published discussion topic" do
    context_type = "Course"
    title = "Test Title"
    message = "A message"
    published = true
    query = <<~GQL
      contextId: "#{@course.id}"
      contextType: "#{context_type}"
      title: "#{title}"
      message: "#{message}"
      published: #{published}
      anonymousState: "off"
    GQL

    result = execute_with_input(query)
    created_discussion_topic = result.dig("data", "createDiscussionTopic", "discussionTopic")

    expect(result["errors"]).to be_nil
    expect(result.dig("data", "discussionTopic", "errors")).to be_nil
    expect(created_discussion_topic["published"]).to be true
  end

  it "creates a full_anonymity discussion topic" do
    context_type = "Course"
    title = "Test Title"
    message = "A message"
    published = true
    anonymous_state = "full_anonymity"
    query = <<~GQL
      contextId: "#{@course.id}"
      contextType: "#{context_type}"
      title: "#{title}"
      message: "#{message}"
      published: #{published}
      anonymousState: "#{anonymous_state}"
    GQL

    result = execute_with_input(query)
    created_discussion_topic = result.dig("data", "createDiscussionTopic", "discussionTopic")

    expect(result["errors"]).to be_nil
    expect(result.dig("data", "discussionTopic", "errors")).to be_nil
    expect(created_discussion_topic["anonymousState"]).to eq anonymous_state
  end

  it "allows teachers to still create anonymous discussions even when students cannot" do
    @course.allow_student_anonymous_discussion_topics = false
    @course.save!

    query = <<~GQL
      contextId: "#{@course.id}"
      contextType: "Course"
      title: "Student Anonymous Create"
      message: "this should return an error"
      published: true
      anonymousState: "full_anonymity"
    GQL

    result = execute_with_input(query, @teacher)
    created_discussion_topic = result.dig("data", "createDiscussionTopic", "discussionTopic")

    expect(result["errors"]).to be_nil
    expect(result.dig("data", "discussionTopic", "errors")).to be_nil
    expect(created_discussion_topic["anonymousState"]).to eq "full_anonymity"
  end

  it "creates a partial_anonymity discussion topic where is_anonymous_author defaults to false" do
    context_type = "Course"
    title = "Test Title"
    message = "A message"
    published = true
    anonymous_state = "partial_anonymity"
    query = <<~GQL
      contextId: "#{@course.id}"
      contextType: "#{context_type}"
      title: "#{title}"
      message: "#{message}"
      published: #{published}
      anonymousState: "#{anonymous_state}"
    GQL

    result = execute_with_input(query)
    created_discussion_topic = result.dig("data", "createDiscussionTopic", "discussionTopic")

    expect(result["errors"]).to be_nil
    expect(result.dig("data", "discussionTopic", "errors")).to be_nil
    expect(created_discussion_topic["anonymousState"]).to eq anonymous_state
    expect(created_discussion_topic["isAnonymousAuthor"]).to be false
  end

  it "creates a partial_anonymity discussion topic with is_anonymous_author set to true" do
    context_type = "Course"
    title = "Test Title"
    message = "A message"
    published = true
    anonymous_state = "partial_anonymity"
    query = <<~GQL
      contextId: "#{@course.id}"
      contextType: "#{context_type}"
      title: "#{title}"
      message: "#{message}"
      published: #{published}
      anonymousState: "#{anonymous_state}"
      isAnonymousAuthor: true
    GQL

    result = execute_with_input(query)
    created_discussion_topic = result.dig("data", "createDiscussionTopic", "discussionTopic")

    expect(result["errors"]).to be_nil
    expect(result.dig("data", "discussionTopic", "errors")).to be_nil
    expect(created_discussion_topic["anonymousState"]).to eq anonymous_state
    expect(created_discussion_topic["isAnonymousAuthor"]).to be true
  end

  it "creates a partial_anonymity discussion topic with is_anonymous_author set to false" do
    context_type = "Course"
    title = "Test Title"
    message = "A message"
    published = true
    anonymous_state = "partial_anonymity"
    query = <<~GQL
      contextId: "#{@course.id}"
      contextType: "#{context_type}"
      title: "#{title}"
      message: "#{message}"
      published: #{published}
      anonymousState: "#{anonymous_state}"
      isAnonymousAuthor: false
    GQL

    result = execute_with_input(query)
    created_discussion_topic = result.dig("data", "createDiscussionTopic", "discussionTopic")

    expect(result["errors"]).to be_nil
    expect(result.dig("data", "discussionTopic", "errors")).to be_nil
    expect(created_discussion_topic["anonymousState"]).to eq anonymous_state
    expect(created_discussion_topic["isAnonymousAuthor"]).to be false
  end

  context "errors" do
    def expect_error(result, message)
      errors = result["errors"] || result.dig("data", "createDiscussionTopic", "errors")
      expect(errors).not_to be_nil
      expect(errors[0]["message"]).to match(/#{message}/)
    end

    context "invalid context" do
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

    context "anonymous_state" do
      it "returns error for anonymous discussions when context is a Group" do
        gc = @course.group_categories.create! name: "foo"
        group = gc.groups.create! context: @course, name: "baz"
        context_type = "Group"
        title = "Test Title"
        message = "A message"
        published = true
        anonymous_state = "partial_anonymity"

        query = <<~GQL
          contextId: "#{group.id}"
          contextType: "#{context_type}"
          title: "#{title}"
          message: "#{message}"
          published: #{published}
          anonymousState: "#{anonymous_state}"
        GQL

        result = execute_with_input(query)
        expect_error(result, "You are not able to create an anonymous discussion in a group")
      end

      it "returns an error for non-teachers without anonymous discussion creation permissions" do
        @course.allow_student_anonymous_discussion_topics = false
        @course.save!
        student_in_course(active_all: true)

        query = <<~GQL
          contextId: "#{@course.id}"
          contextType: "Course"
          title: "Student Anonymous Create"
          message: "this should return an error"
          published: true
          anonymousState: "full_anonymity"
        GQL

        result = execute_with_input(query, @student)
        expect_error(result, "You are not able to create an anonymous discussion")
      end
    end
  end

  context "delayed_post_at and lock_at" do
    it "successfully creates a discussion topic with delayed_post_at and lock_at" do
      context_type = "Course"
      title = "Delayed Topic"
      message = "Lorem ipsum..."
      published = false
      require_initial_post = true
      delayed_post_at = 5.days.from_now.iso8601
      lock_at = 10.days.from_now.iso8601

      query = <<~GQL
        contextId: "#{@course.id}"
        contextType: "#{context_type}"
        title: "#{title}"
        message: "#{message}"
        published: #{published}
        requireInitialPost: #{require_initial_post}
        anonymousState: "off"
        delayedPostAt: "#{delayed_post_at}"
        lockAt: "#{lock_at}"
      GQL

      result = execute_with_input(query)
      discussion_topic = result.dig("data", "createDiscussionTopic", "discussionTopic")

      expect(result["errors"]).to be_nil
      expect(result.dig("data", "discussionTopic", "errors")).to be_nil
      expect(discussion_topic["delayedPostAt"]).to eq delayed_post_at
      expect(discussion_topic["lockAt"]).to eq lock_at
      expect(DiscussionTopic.last.workflow_state).to eq "post_delayed"
    end

    it "successfully creates a discussion topic with lock_at only" do
      context_type = "Course"
      title = "Delayed Topic"
      message = "Lorem ipsum..."
      published = false
      require_initial_post = true
      lock_at = 5.days.from_now.iso8601

      query = <<~GQL
        contextId: "#{@course.id}"
        contextType: "#{context_type}"
        title: "#{title}"
        message: "#{message}"
        published: #{published}
        requireInitialPost: #{require_initial_post}
        anonymousState: "off"
        lockAt: "#{lock_at}"
      GQL

      result = execute_with_input(query)
      discussion_topic = result.dig("data", "createDiscussionTopic", "discussionTopic")

      expect(result["errors"]).to be_nil
      expect(result.dig("data", "discussionTopic", "errors")).to be_nil
      expect(discussion_topic["delayedPostAt"]).to be_nil
      expect(discussion_topic["lockAt"]).to eq lock_at
      expect(DiscussionTopic.last.workflow_state).to eq "unpublished"
    end

    it "successfully creates a discussion topic with null delayed_post_at and lock_at" do
      context_type = "Course"
      title = "Topic w/null delayed_post_at and lock_at"
      message = "Lorem ipsum..."
      published = false
      require_initial_post = true
      delayed_post_at = "null"
      lock_at = "null"

      query = <<~GQL
        contextId: "#{@course.id}"
        contextType: "#{context_type}"
        title: "#{title}"
        message: "#{message}"
        published: #{published}
        requireInitialPost: #{require_initial_post}
        anonymousState: "off"
        delayedPostAt: #{delayed_post_at}
        lockAt: #{lock_at}
      GQL

      result = execute_with_input(query)
      discussion_topic = result.dig("data", "createDiscussionTopic", "discussionTopic")

      expect(result["errors"]).to be_nil
      expect(result.dig("data", "discussionTopic", "errors")).to be_nil
      expect(discussion_topic["delayedPostAt"]).to be_nil
      expect(discussion_topic["lockAt"]).to be_nil
    end
  end
end
