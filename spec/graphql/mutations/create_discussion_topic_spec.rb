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
            todoDate
            podcastEnabled
            podcastHasStudentPosts
            isSectionSpecific
            expanded
            expandedLocked
            sortOrder
            sortOrderLocked
            ungradedDiscussionOverrides {
              nodes {
                _id
                title
              }
            }
            groupSet {
              _id
            }
            courseSections{
              _id
              name
            }
            attachment{
              _id
            }
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

  def execute_with_input_with_assignment(create_input, current_user = @teacher)
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
            todoDate
            podcastEnabled
            podcastHasStudentPosts
            isSectionSpecific
            replyToEntryRequiredCount
            expanded
            expandedLocked
            sortOrder
            sortOrderLocked
            groupSet {
              _id
            }
            courseSections{
              _id
              name
            }
            assignment {
              _id
              name
              pointsPossible
              gradingType
              importantDates
              groupSet {
                _id
              }
              peerReviews {
                anonymousReviews
                automaticReviews
                count
                enabled
              }
              assignmentOverrides {
                nodes {
                  _id
                  title
                }
              }
              checkpoints {
                dueAt
                name
                onlyVisibleToOverrides
                pointsPossible
                tag
              }
            }
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
      contextType: #{context_type}
      title: "#{title}"
      message: "#{message}"
      published: #{published}
      requireInitialPost: #{require_initial_post}
      anonymousState: off
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
    expect(created_discussion_topic["todoDate"]).to be_nil
    expect(created_discussion_topic["podcastEnabled"]).to be false
    expect(created_discussion_topic["podcastHasStudentPosts"]).to be false
    expect(created_discussion_topic["isSectionSpecific"]).to be false
    expect(created_discussion_topic["expanded"]).to be false
    expect(created_discussion_topic["expandedLocked"]).to be false
    expect(created_discussion_topic["sortOrder"]).to eq DiscussionTopic::SortOrder::DESC
    expect(created_discussion_topic["sortOrderLocked"]).to be false
    expect(DiscussionTopic.where("id = #{created_discussion_topic["_id"]}").count).to eq 1
  end

  it "successfully creates an announcement" do
    is_announcement = true
    context_type = "Course"
    title = "Test Title"
    message = "A message"
    published = true
    require_initial_post = true

    query = <<~GQL
      isAnnouncement: #{is_announcement}
      contextId: "#{@course.id}"
      contextType: #{context_type}
      title: "#{title}"
      message: "#{message}"
      published: #{published}
      requireInitialPost: #{require_initial_post}
      anonymousState: off
    GQL

    result = execute_with_input(query)
    created_announcement = result.dig("data", "createDiscussionTopic", "discussionTopic")

    expect(result["errors"]).to be_nil
    expect(result.dig("data", "discussionTopic", "errors")).to be_nil

    expect(created_announcement["contextType"]).to eq context_type
    expect(created_announcement["title"]).to eq title
    expect(created_announcement["message"]).to eq message
    expect(created_announcement["published"]).to eq published
    expect(created_announcement["requireInitialPost"]).to be true
    expect(created_announcement["anonymousState"]).to be_nil
    expect(created_announcement["allowRating"]).to be false
    expect(created_announcement["onlyGradersCanRate"]).to be false
    expect(created_announcement["todoDate"]).to be_nil
    expect(created_announcement["podcastEnabled"]).to be false
    expect(created_announcement["podcastHasStudentPosts"]).to be false
    expect(Announcement.where("id = #{created_announcement["_id"]}").count).to eq 1
  end

  it "successfully creates a locked announcement" do
    is_announcement = true
    context_type = "Course"
    title = "Test Title"
    message = "A message"
    published = true
    require_initial_post = false
    locked = true
    lock_at = 10.days.from_now.iso8601

    query = <<~GQL
      isAnnouncement: #{is_announcement}
      contextId: "#{@course.id}"
      contextType: #{context_type}
      title: "#{title}"
      message: "#{message}"
      published: #{published}
      requireInitialPost: #{require_initial_post}
      anonymousState: off
      locked: #{locked}
      lockAt: "#{lock_at}"
    GQL

    result = execute_with_input(query)
    created_announcement = result.dig("data", "createDiscussionTopic", "discussionTopic")

    expect(result["errors"]).to be_nil
    expect(result.dig("data", "discussionTopic", "errors")).to be_nil

    announcement = Announcement.find(created_announcement["_id"])

    expect(announcement.locked_announcement?).to be true
    expect(announcement.workflow_state).to eq "active"
    expect(announcement.lock_at).to eq lock_at
    @teacher.reload
    expect(@teacher.create_announcements_unlocked?).to eq !locked
  end

  it "successfully creates an unlocked announcement" do
    is_announcement = true
    context_type = "Course"
    title = "Test Title"
    message = "A message"
    published = true
    require_initial_post = false
    locked = false

    query = <<~GQL
      isAnnouncement: #{is_announcement}
      contextId: "#{@course.id}"
      contextType: #{context_type}
      title: "#{title}"
      message: "#{message}"
      published: #{published}
      requireInitialPost: #{require_initial_post}
      anonymousState: off
      locked: #{locked}
    GQL

    result = execute_with_input(query)
    created_announcement = result.dig("data", "createDiscussionTopic", "discussionTopic")

    expect(result["errors"]).to be_nil
    expect(result.dig("data", "discussionTopic", "errors")).to be_nil

    announcement = Announcement.find(created_announcement["_id"])

    expect(announcement.locked_announcement?).to be false
    expect(announcement.workflow_state).to eq "active"
    @teacher.reload
    expect(@teacher.create_announcements_unlocked?).to eq !locked
  end

  it "successfully creates a section specific announcement" do
    is_announcement = true
    context_type = "Course"
    title = "Test Title"
    message = "A message"
    published = true
    require_initial_post = true

    section = add_section("New Section")

    query = <<~GQL
      isAnnouncement: #{is_announcement}
      contextId: "#{@course.id}"
      contextType: #{context_type}
      title: "#{title}"
      message: "#{message}"
      published: #{published}
      requireInitialPost: #{require_initial_post}
      anonymousState: off
      specificSections: "#{section.id}"
    GQL

    result = execute_with_input(query)
    created_announcement = result.dig("data", "createDiscussionTopic", "discussionTopic")

    expect(result["errors"]).to be_nil
    expect(result.dig("data", "discussionTopic", "errors")).to be_nil

    expect(Announcement.where("id = #{created_announcement["_id"]}").count).to eq 1
    expect(created_announcement["isSectionSpecific"]).to be true
    expect(created_announcement["courseSections"][0]["name"]).to eq("New Section")
  end

  it "creates an allow_rating discussion topic" do
    query = <<~GQL
      contextId: "#{@course.id}"
      contextType: Course
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
      contextType: Course
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
      contextType: #{context_type}
      title: "#{title}"
      message: "#{message}"
      published: #{published}
      anonymousState: off
    GQL

    result = execute_with_input(query)
    created_discussion_topic = result.dig("data", "createDiscussionTopic", "discussionTopic")

    expect(result["errors"]).to be_nil
    expect(result.dig("data", "discussionTopic", "errors")).to be_nil
    expect(created_discussion_topic["published"]).to be true
  end

  it "creates a topic with an attachment" do
    attachment = attachment_with_context(@teacher)
    attachment.update!(user: @teacher)

    context_type = "Course"
    title = "Test Title"
    message = "A message"
    published = true
    file_id = attachment.id
    query = <<~GQL
      contextId: "#{@course.id}"
      contextType: #{context_type}
      title: "#{title}"
      message: "#{message}"
      published: #{published}
      anonymousState: off
      fileId: "#{file_id}"
    GQL

    result = execute_with_input(query)
    created_discussion_topic = result.dig("data", "createDiscussionTopic", "discussionTopic")
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "discussionTopic", "errors")).to be_nil
    expect(created_discussion_topic["attachment"]["_id"]).to eq(attachment.id.to_s)
  end

  it "creates a full_anonymity discussion topic" do
    context_type = "Course"
    title = "Test Title"
    message = "A message"
    published = true
    anonymous_state = "full_anonymity"
    query = <<~GQL
      contextId: "#{@course.id}"
      contextType: #{context_type}
      title: "#{title}"
      message: "#{message}"
      published: #{published}
      anonymousState: #{anonymous_state}
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
      contextType: Course
      title: "Student Anonymous Create"
      message: "this should not return an error"
      published: true
      anonymousState: full_anonymity
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
      contextType: #{context_type}
      title: "#{title}"
      message: "#{message}"
      published: #{published}
      anonymousState: #{anonymous_state}
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
      contextType: #{context_type}
      title: "#{title}"
      message: "#{message}"
      published: #{published}
      anonymousState: #{anonymous_state}
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
      contextType: #{context_type}
      title: "#{title}"
      message: "#{message}"
      published: #{published}
      anonymousState: #{anonymous_state}
      isAnonymousAuthor: false
    GQL

    result = execute_with_input(query)
    created_discussion_topic = result.dig("data", "createDiscussionTopic", "discussionTopic")

    expect(result["errors"]).to be_nil
    expect(result.dig("data", "discussionTopic", "errors")).to be_nil
    expect(created_discussion_topic["anonymousState"]).to eq anonymous_state
    expect(created_discussion_topic["isAnonymousAuthor"]).to be false
  end

  it "creates a todo_date discussion topic" do
    @course.allow_student_anonymous_discussion_topics = false
    @course.save!

    todo_date = 5.days.from_now.iso8601

    query = <<~GQL
      contextId: "#{@course.id}"
      contextType: Course
      title: "TODO Discussion"
      published: true
      anonymousState: full_anonymity
      todoDate: "#{todo_date}"
    GQL

    result = execute_with_input(query, @teacher)
    created_discussion_topic = result.dig("data", "createDiscussionTopic", "discussionTopic")

    expect(result["errors"]).to be_nil
    expect(result.dig("data", "discussionTopic", "errors")).to be_nil
    expect(created_discussion_topic["todoDate"]).to eq todo_date
  end

  it "successfully creates the discussion topic with podcast_enabled and podcast_has_student_posts" do
    context_type = "Course"
    title = "Test Title"
    message = "A message"
    published = false
    require_initial_post = true
    podcast_enabled = true
    podcast_has_student_posts = true

    query = <<~GQL
      contextId: "#{@course.id}"
      contextType: #{context_type}
      title: "#{title}"
      message: "#{message}"
      published: #{published}
      requireInitialPost: #{require_initial_post}
      anonymousState: off
      podcastEnabled: #{podcast_enabled}
      podcastHasStudentPosts: #{podcast_has_student_posts}
    GQL

    result = execute_with_input(query)
    created_discussion_topic = result.dig("data", "createDiscussionTopic", "discussionTopic")

    expect(result["errors"]).to be_nil
    expect(result.dig("data", "discussionTopic", "errors")).to be_nil

    expect(created_discussion_topic["podcastEnabled"]).to be true
    expect(created_discussion_topic["podcastHasStudentPosts"]).to be true
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
          contextType: Course
        GQL
        result = execute_with_input(query)
        expect_error(result, "Not found")
      end

      it "returns 'invalid context' with an incorrect context type" do
        query = <<~GQL
          contextId: "1"
          contextType: NotAContextType
        GQL
        result = execute_with_input(query)
        expected_error_message = "Argument 'contextType' on InputObject 'CreateDiscussionTopicInput' has an invalid value \\(NotAContextType\\)\\. Expected type 'DiscussionTopicContextType!'\\."
        expect_error(result, expected_error_message)
      end
    end

    context "anonymous_state" do
      it "returns error for anonymous discussions when a group_category_id is passed" do
        context_type = "Course"
        title = "Test Title"
        message = "A message"
        published = true
        anonymous_state = "full_anonymity"
        group_category_id = 1

        query = <<~GQL
          contextId: "#{@course.id}"
          contextType: #{context_type}
          title: "#{title}"
          message: "#{message}"
          published: #{published}
          anonymousState: #{anonymous_state}
          groupCategoryId: "#{group_category_id}"
        GQL

        result = execute_with_input(query)
        expect_error(result, "You are not able to create a group anonymous discussion")
      end

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
          contextType: #{context_type}
          title: "#{title}"
          message: "#{message}"
          published: #{published}
          anonymousState: #{anonymous_state}
        GQL

        result = execute_with_input(query)
        expect_error(result, "You are not able to create a group anonymous discussion")
      end

      it "returns an error for non-teachers without anonymous discussion creation permissions" do
        @course.allow_student_anonymous_discussion_topics = false
        @course.save!
        student_in_course(active_all: true)

        query = <<~GQL
          contextId: "#{@course.id}"
          contextType: Course
          title: "Student Anonymous Create"
          message: "this should return an error"
          published: true
          anonymousState: full_anonymity
        GQL

        result = execute_with_input(query, @student)
        expect_error(result, "You are not able to create an anonymous discussion")
      end
    end

    context "todo_date" do
      it "returns an error when user has no manage_course_content_add permissions" do
        todo_date = 5.days.from_now.iso8601
        query = <<~GQL
          contextId: "#{@course.id}"
          contextType: Course,
          todoDate: "#{todo_date}"
        GQL

        result = execute_with_input(query, @student)
        expect_error(result, "You do not have permission to add this topic to the student to-do list.")
      end
    end

    context "checkpoints" do
      before(:once) do
        @course.account.enable_feature!(:discussion_checkpoints)
      end

      context "Restrict Quantitative Data" do
        it "returns an error if disccussion has checkpoints and RQD is enabled" do
          @course.restrict_quantitative_data = true
          @course.save!
          context_type = "Course"
          title = "Graded Discussion w/Checkpoints"
          message = "Lorem ipsum..."
          published = true

          query = <<~GQL
            contextId: "#{@course.id}"
            contextType: #{context_type}
            title: "#{title}"
            message: "#{message}"
            published: #{published}
            assignment: {
              courseId: "#{@course.id}",
              name: "#{title}",
              forCheckpoints: true,
            }
            checkpoints: [
              {
                checkpointLabel: reply_to_topic,
                pointsPossible: 10,
                dates: [{ type: everyone, dueAt: "#{5.days.from_now.iso8601}" }]
              },
              {
                checkpointLabel: reply_to_entry,
                pointsPossible: 15,
                dates: [{ type: everyone, dueAt: "#{10.days.from_now.iso8601}" }],
                repliesRequired: 3
              }
            ]
          GQL
          result = execute_with_input_with_assignment(query)
          expect_error(result, "If Restrict Quantitative Data is enabled, checkpoints cannot be created")
        end
      end

      it "returns an error if the sum of possible points for the checkpoints exceeds the max for the assignment" do
        context_type = "Course"
        title = "Graded Discussion w/Checkpoints"
        message = "Lorem ipsum..."
        published = true

        query = <<~GQL
          contextId: "#{@course.id}"
          contextType: #{context_type}
          title: "#{title}"
          message: "#{message}"
          published: #{published}
          assignment: {
            courseId: "#{@course.id}",
            name: "#{title}",
            forCheckpoints: true,
          }
          checkpoints: [
            {
              checkpointLabel: reply_to_topic,
              pointsPossible: 999999999,
              dates: []
            },
            {
              checkpointLabel: reply_to_entry,
              pointsPossible: 1,
              dates: [],
              repliesRequired: 3
            }
          ]
        GQL
        result = execute_with_input_with_assignment(query)
        expect_error(result, "The value of possible points for this assignment cannot exceed 999999999.")
      end
    end
  end

  context "sections" do
    it "successfully creates the discussion topic is_section_specific false" do
      context_type = "Course"
      title = "Test Title"
      message = "A message"
      published = false
      require_initial_post = true
      query = <<~GQL
        contextId: "#{@course.id}"
        contextType: #{context_type}
        title: "#{title}"
        message: "#{message}"
        published: #{published}
        requireInitialPost: #{require_initial_post}
        anonymousState: off
        specificSections: "all"
      GQL

      result = execute_with_input(query)
      created_discussion_topic = result.dig("data", "createDiscussionTopic", "discussionTopic")

      expect(result["errors"]).to be_nil
      expect(result.dig("data", "discussionTopic", "errors")).to be_nil
      expect(created_discussion_topic["contextType"]).to eq context_type
      expect(created_discussion_topic["title"]).to eq title
      expect(created_discussion_topic["isSectionSpecific"]).to be false
      expect(DiscussionTopic.where("id = #{created_discussion_topic["_id"]}").count).to eq 1
    end
  end

  context "delayed_post_at and lock_at" do
    it "successfully creates an unpublished discussion topic with delayed_post_at and lock_at" do
      context_type = "Course"
      title = "Delayed Topic"
      message = "Lorem ipsum..."
      published = false
      require_initial_post = true
      delayed_post_at = 5.days.from_now.iso8601
      lock_at = 10.days.from_now.iso8601

      query = <<~GQL
        contextId: "#{@course.id}"
        contextType: #{context_type}
        title: "#{title}"
        message: "#{message}"
        published: #{published}
        requireInitialPost: #{require_initial_post}
        anonymousState: off
        delayedPostAt: "#{delayed_post_at}"
        lockAt: "#{lock_at}"
      GQL

      result = execute_with_input(query)
      discussion_topic = result.dig("data", "createDiscussionTopic", "discussionTopic")

      expect(result["errors"]).to be_nil
      expect(result.dig("data", "discussionTopic", "errors")).to be_nil
      expect(discussion_topic["delayedPostAt"]).to eq delayed_post_at
      expect(discussion_topic["lockAt"]).to eq lock_at
      expect(DiscussionTopic.last.workflow_state).to eq "unpublished"
    end

    it "coerces a created published discussion into post_delayed if delayed_post_at is in the future" do
      context_type = "Course"
      title = "Delayed Topic"
      message = "Lorem ipsum..."
      published = true
      require_initial_post = true
      delayed_post_at = 5.days.from_now.iso8601
      lock_at = 10.days.from_now.iso8601

      query = <<~GQL
        contextId: "#{@course.id}"
        contextType: #{context_type}
        title: "#{title}"
        message: "#{message}"
        published: #{published}
        requireInitialPost: #{require_initial_post}
        anonymousState: off
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
        contextType: #{context_type}
        title: "#{title}"
        message: "#{message}"
        published: #{published}
        requireInitialPost: #{require_initial_post}
        anonymousState: off
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
        contextType: #{context_type}
        title: "#{title}"
        message: "#{message}"
        published: #{published}
        requireInitialPost: #{require_initial_post}
        anonymousState: off
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

  context "graded discussion topics" do
    it "successfully creates a graded discussion topic" do
      context_type = "Course"
      title = "Graded Discussion"
      message = "Lorem ipsum..."
      published = true
      student = @course.enroll_student(User.create!, enrollment_state: "active").user
      group_category = @course.group_categories.create! name: "foo"
      lock_at = 5.days.from_now.iso8601

      query = <<~GQL
        contextId: "#{@course.id}"
        contextType: #{context_type}
        title: "#{title}"
        message: "#{message}"
        published: #{published}
        groupCategoryId: "#{group_category.id}"
        lockAt: null
        assignment: {
          courseId: "#{@course.id}",
          name: "#{title}",
          lockAt: "#{lock_at}",
          pointsPossible: 15,
          gradingType: percent,
          postToSis: true,
          importantDates: true,
          peerReviews: {
            anonymousReviews: true,
            automaticReviews: true,
            count: 2,
            enabled: true,
            intraReviews: true,
            dueAt: "#{5.days.from_now.iso8601}",
          }
          assignmentOverrides: {
            studentIds: ["#{student.id}"]
          }
        }
      GQL

      result = execute_with_input_with_assignment(query)
      assignment = Assignment.last
      discussion_topic = result.dig("data", "createDiscussionTopic", "discussionTopic")
      aggregate_failures do
        expect(result.dig("data", "discussionTopic", "errors")).to be_nil
        expect(discussion_topic["assignment"]["name"]).to eq title
        expect(discussion_topic["assignment"]["pointsPossible"]).to eq 15
        expect(discussion_topic["assignment"]["gradingType"]).to eq "percent"
        expect(discussion_topic["assignment"]["importantDates"]).to be true
        expect(discussion_topic["assignment"]["peerReviews"]["anonymousReviews"]).to be true
        expect(discussion_topic["assignment"]["peerReviews"]["automaticReviews"]).to be true
        expect(discussion_topic["assignment"]["peerReviews"]["count"]).to eq 2
        expect(discussion_topic["assignment"]["assignmentOverrides"]["nodes"]).to match([{ "_id" => assignment.assignment_overrides.first.id.to_s, "title" => assignment.assignment_overrides.first.title }])
        expect(discussion_topic["assignment"]["_id"]).to eq assignment.id.to_s
        expect(discussion_topic["_id"]).to eq assignment.discussion_topic.id.to_s
        expect(DiscussionTopic.count).to eq 1
        expect(DiscussionTopic.last.assignment.post_to_sis).to be true
        expect(DiscussionTopic.last.lock_at).to eq(lock_at)
      end
    end

    it "successfully creates a graded discussion topic with a group override" do
      context_type = "Course"
      title = "Graded Discussion"
      message = "Lorem ipsum..."
      published = true
      @course.enroll_student(User.create!, enrollment_state: "active").user
      group_category = @course.group_categories.create! name: "foo"
      group = group_category.groups.create! name: "bar", context: @course

      query = <<~GQL
        contextId: "#{@course.id}"
        contextType: #{context_type}
        title: "#{title}"
        message: "#{message}"
        published: #{published}
        groupCategoryId: "#{group_category.id}"
        assignment: {
          courseId: "#{@course.id}",
          name: "#{title}",
          pointsPossible: 15,
          postToSis: true,
          assignmentOverrides: {
            groupId: "#{group.id}"
          }
        }
      GQL

      result = execute_with_input_with_assignment(query)
      assignment = Assignment.last
      discussion_topic = result.dig("data", "createDiscussionTopic", "discussionTopic")
      override = assignment.assignment_overrides.first
      aggregate_failures do
        expect(result.dig("data", "discussionTopic", "errors")).to be_nil
        expect(discussion_topic["assignment"]["name"]).to eq title
        expect(discussion_topic["assignment"]["pointsPossible"]).to eq 15
        expect(discussion_topic["assignment"]["assignmentOverrides"]["nodes"]).to match([{ "_id" => assignment.assignment_overrides.first.id.to_s, "title" => assignment.assignment_overrides.first.title }])
        expect(discussion_topic["assignment"]["_id"]).to eq assignment.id.to_s
        expect(discussion_topic["_id"]).to eq assignment.discussion_topic.id.to_s
        expect(DiscussionTopic.count).to eq 2
        expect(DiscussionTopic.last.assignment.post_to_sis).to be true
        expect(override.assignment_id).to eq assignment.id
        expect(override.workflow_state).to eq "active"
      end
    end

    it "successfully creates a graded discussion topic with new LTI Asset Processors" do
      tool = lti_registration_with_tool(account: @course.account).deployments.first

      query = <<~GQL
        contextId: "#{@course.id}"
        contextType: Course
        title: "Discussion"
        assignment: {
          courseId: "#{@course.id}"
          name: "Discussion"
          assetProcessors: [
            {
              newContentItem: {
                contextExternalToolId: #{tool.id}
                url: "https://example.com/lti-tool"
                title: "My AP"
                text: "My AP Text"
                icon: { url: "https://example.com/icon.png", width: 50, height: 50 }
                thumbnail: { url: "https://example.com/thumbnail.png", width: 50, height: 50 }
                window: { targetName: "_blank", width: 800, height: 600, windowFeatures: "popup=true,left=0" }
                iframe: { width: 800, height: 600 }
                custom: { custom_param_1: "custom_value_1", custom_param_2: "custom_value_2" }
                report: {
                  url: "https://example.com/report-url"
                  custom: { report_param_1: "report_value_1" }
                }
              }
            }
            {
              newContentItem: {
                contextExternalToolId: #{tool.id}
                title: "My AP2"
              }
            }
          ]
        }
      GQL

      result = execute_with_input_with_assignment(query)
      expect(result.dig("data", "createDiscussionTopic", "errors")).to be_nil
      assignment = Assignment.last
      expect(assignment.lti_asset_processors.count).to eq 2
      aggregate_failures do
        expect(result.dig("data", "createDiscussionTopic", "errors")).to be_nil
        ap1 = assignment.lti_asset_processors.first
        ap2 = assignment.lti_asset_processors.last
        expect(ap1.context_external_tool_id).to eq tool.id
        expect(ap1.url).to eq "https://example.com/lti-tool"
        expect(ap1.title).to eq "My AP"
        expect(ap1.text).to eq "My AP Text"
        expect(ap1.icon).to eq({ "url" => "https://example.com/icon.png", "width" => 50, "height" => 50 })
        # thumbnail accepted, but ignored
        expect(ap1.window).to eq({ "targetName" => "_blank", "width" => 800, "height" => 600, "windowFeatures" => "popup=true,left=0" })
        expect(ap1.iframe).to eq({ "width" => 800, "height" => 600 })
        expect(ap1.custom).to eq({ "custom_param_1" => "custom_value_1", "custom_param_2" => "custom_value_2" })
        expect(ap1.report).to eq({ "url" => "https://example.com/report-url", "custom" => { "report_param_1" => "report_value_1" } })
        expect(ap2.context_external_tool_id).to eq tool.id
        expect(ap2.title).to eq "My AP2"
        expect(ap2.text).to be_nil
      end
    end

    it "requires custom parameters values to be strings for LTI Asset Processors" do
      tool = lti_registration_with_tool(account: @course.account).deployments.first

      query = <<~GQL
        contextId: "#{@course.id}"
        contextType: Course
        title: "Discussion"
        assignment: {
          courseId: "#{@course.id}"
          name: "Discussion"
          assetProcessors: [
            {
              newContentItem: {
                contextExternalToolId: #{tool.id}
                custom: { custom_param_1: 123, custom_param_2: true }
                report: {
                  custom: { report_param_1: { foo: "bar" } }
                }
              }
            }
          ]
        }
      GQL
      expect do
        result = execute_with_input_with_assignment(query)
        expect(result["errors"]).not_to be_nil
        expect(result["errors"][0]["message"]).to match(/custom_param_1.*StringMap/)
        expect(result["errors"][1]["message"]).to match(/report_param_1.*StringMap/)
      end.not_to change { Assignment.count }
    end

    it "does not create LTI asset processors if the feature flag is disabled" do
      @course.account.disable_feature!(:lti_asset_processor_discussions)
      tool = lti_registration_with_tool(account: @course.account).deployments.first

      query = <<~GQL
        contextId: "#{@course.id}"
        contextType: Course
        title: "Discussion"
        assignment: {
          courseId: "#{@course.id}"
          name: "Discussion"
          assetProcessors: [
            {
              newContentItem: {
                contextExternalToolId: #{tool.id}
              }
            }
          ]
        }
      GQL
      expect do
        result = execute_with_input_with_assignment(query)
        expect(result["errors"]).to be_nil
        expect(Assignment.last.lti_asset_processors.count).to eq 0
      end.to change { Assignment.count }.by(1)
    end

    it "student fails to create graded discussion topic" do
      context_type = "Course"
      title = "Graded Discussion"
      message = "Lorem ipsum..."
      published = true

      query = <<~GQL
        contextId: "#{@course.id}"
        contextType: #{context_type}
        title: "#{title}"
        message: "#{message}"
        published: #{published}
        assignment: {
          courseId: "#{@course.id}",
          name: "#{title}",
          pointsPossible: 15,
          gradingType: percent,
          peerReviews: {
            anonymousReviews: true,
            automaticReviews: true,
            count: 2,
            enabled: true,
            intraReviews: true,
            dueAt: "#{5.days.from_now.iso8601}",
          }
        }
      GQL

      student = @course.enroll_student(User.create!, enrollment_state: "active").user
      result = execute_with_input_with_assignment(query, student)
      discussion_topic = result.dig("data", "createDiscussionTopic", "discussionTopic")
      expect(discussion_topic).to be_nil
      expect(result["errors"][0]["message"]).to eq "invalid course: #{@course.id}"
    end

    it "error for: assignment context_id must match discussion topic context_id" do
      context_type = "Course"
      title = "Graded Discussion"
      message = "Lorem ipsum..."
      published = true

      course2 = Course.create!(name: "Course 2", workflow_state: "active")

      query = <<~GQL
        contextId: "#{@course.id}"
        contextType: #{context_type}
        title: "#{title}"
        message: "#{message}"
        published: #{published}
        assignment: {
          courseId: "#{course2.id}",
          name: "#{title}",
          pointsPossible: 15,
          gradingType: percent,
          peerReviews: {
            anonymousReviews: true,
            automaticReviews: true,
            count: 2,
            enabled: true,
            intraReviews: true,
            dueAt: "#{5.days.from_now.iso8601}",
          }
        }
      GQL

      result = execute_with_input_with_assignment(query)
      discussion_topic = result.dig("data", "createDiscussionTopic", "discussionTopic")
      expect(discussion_topic).to be_nil
      expect(result["data"]["createDiscussionTopic"]["errors"][0]["message"]).to eq "Assignment context_id must match discussion topic context_id"
    end

    it "error: unknown student ids" do
      context_type = "Course"
      title = "Graded Discussion"
      message = "Lorem ipsum..."
      published = true

      query = <<~GQL
        contextId: "#{@course.id}"
        contextType: #{context_type}
        title: "#{title}"
        message: "#{message}"
        published: #{published}
        assignment: {
          courseId: "#{@course.id}",
          name: "#{title}",
          pointsPossible: 15,
          gradingType: percent,
          assignmentOverrides: {
            studentIds: ["#{@teacher.id - 1}"]
          }
        }
      GQL

      result = execute_with_input_with_assignment(query)
      discussion_topic = result.dig("data", "createDiscussionTopic", "discussionTopic")
      expect(discussion_topic).to be_nil
      expect(result["data"]["createDiscussionTopic"]["errors"][0]["message"]).to eq "[[:base, \"unknown student ids: [\\\"#{@teacher.id - 1}\\\"]\"]]"
    end

    it "sets the ab_guid on the assignment" do
      context_type = "Course"
      title = "Graded Discussion"
      message = "Lorem ipsum..."
      published = true

      query = <<~GQL
        contextId: "#{@course.id}"
        contextType: #{context_type}
        title: "#{title}"
        message: "#{message}"
        published: #{published}
        assignment: {
          courseId: "#{@course.id}",
          name: "#{title}",
          pointsPossible: 15,
          gradingType: percent,
          abGuid: ["1E20776E-7053-11DF-8EBF-BE719DFF4B22", "1e20776e-7053-11df-8eBf-Be719dff4b22"]
        }
      GQL

      execute_with_input_with_assignment(query)

      expect(Assignment.last.ab_guid).to eq(["1E20776E-7053-11DF-8EBF-BE719DFF4B22", "1e20776e-7053-11df-8eBf-Be719dff4b22"])
    end
  end

  context "checkpoints" do
    before(:once) do
      @course.account.enable_feature!(:discussion_checkpoints)
    end

    it "successfully creates a discussion topic with checkpoints" do
      context_type = "Course"
      title = "Graded Discussion w/Checkpoints"
      message = "Lorem ipsum..."
      published = true

      query = <<~GQL
        contextId: "#{@course.id}"
        contextType: #{context_type}
        title: "#{title}"
        message: "#{message}"
        published: #{published}
        assignment: {
          courseId: "#{@course.id}",
          name: "#{title}",
          forCheckpoints: true,
        }
        checkpoints: [
          {
            checkpointLabel: reply_to_topic,
            pointsPossible: 10,
            dates: [{ type: everyone, dueAt: "#{5.days.from_now.iso8601}" }]
          },
          {
            checkpointLabel: reply_to_entry,
            pointsPossible: 15,
            dates: [{ type: everyone, dueAt: "#{10.days.from_now.iso8601}" }],
            repliesRequired: 3
          }
        ]
      GQL

      result = execute_with_input_with_assignment(query)
      discussion_topic = result.dig("data", "createDiscussionTopic", "discussionTopic")
      reply_to_topic_checkpoint = discussion_topic["assignment"]["checkpoints"].find { |checkpoint| checkpoint["tag"] == CheckpointLabels::REPLY_TO_TOPIC }
      reply_to_entry_checkpoint = discussion_topic["assignment"]["checkpoints"].find { |checkpoint| checkpoint["tag"] == CheckpointLabels::REPLY_TO_ENTRY }
      aggregate_failures do
        expect(result["errors"]).to be_nil
        expect(discussion_topic["assignment"]["checkpoints"][0]["name"]).to eq title
        expect(reply_to_topic_checkpoint).to be_truthy
        expect(reply_to_entry_checkpoint).to be_truthy
        expect(reply_to_topic_checkpoint["pointsPossible"]).to eq 10
        expect(reply_to_entry_checkpoint["pointsPossible"]).to eq 15
        expect(discussion_topic["replyToEntryRequiredCount"]).to eq 3
      end
    end

    it "successfully creates a discussion topic with checkpoints using dueAt, lockAt, unlockAt" do
      context_type = "Course"
      title = "Graded Discussion w/Checkpoints"
      message = "Lorem ipsum..."
      published = true
      due_at = 5.days.from_now
      lock_at = 12.days.from_now
      unlock_at = 2.days.from_now

      query = <<~GQL
        contextId: "#{@course.id}"
        contextType: #{context_type}
        title: "#{title}"
        message: "#{message}"
        published: #{published}
        assignment: {
          courseId: "#{@course.id}",
          name: "#{title}",
          forCheckpoints: true
        }
        checkpoints: [
          {
            checkpointLabel: reply_to_topic,
            pointsPossible: 10,
            dates: [{ type: everyone, dueAt: "#{due_at.iso8601}", lockAt: "#{lock_at.iso8601}", unlockAt: "#{unlock_at.iso8601}" }]
          },
          {
            checkpointLabel: reply_to_entry,
            pointsPossible: 15,
            dates: [{ type: everyone, dueAt: "#{10.days.from_now.iso8601}", lockAt: "#{lock_at.iso8601}", unlockAt: "#{unlock_at.iso8601}" }],
            repliesRequired: 3
          }
        ]
      GQL

      result = execute_with_input_with_assignment(query)
      expect(result["errors"]).to be_nil

      checkpoint = SubAssignment.find_by(sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC)
      checkpoint2 = SubAssignment.find_by(sub_assignment_tag: CheckpointLabels::REPLY_TO_ENTRY)

      expect(checkpoint.due_at).to be_within(1.second).of due_at
      expect(checkpoint.lock_at).to be_within(1.second).of lock_at
      expect(checkpoint.unlock_at).to be_within(1.second).of unlock_at
      expect(checkpoint2.lock_at).to be_within(1.second).of lock_at
      expect(checkpoint2.unlock_at).to be_within(1.second).of unlock_at

      parent_assignment = Assignment.last
      expect(parent_assignment.lock_at).to be_within(1.second).of lock_at
      expect(parent_assignment.unlock_at).to be_within(1.second).of unlock_at
    end

    it "successfully creates a discussion topic with checkpoints and CourseSection overrides" do
      section1 = add_section("M03")
      section2 = add_section("M06")

      context_type = "Course"
      title = "Graded Discussion w/Checkpoints and CourseSection overrides"
      message = "Lorem ipsum..."
      published = true

      reply_to_entry_due_at1 = 12.days.from_now
      reply_to_entry_due_at2 = 14.days.from_now

      query = <<~GQL
        contextId: "#{@course.id}"
        contextType: #{context_type}
        title: "#{title}"
        message: "#{message}"
        published: #{published}
        assignment: {
          courseId: "#{@course.id}",
          name: "#{title}",
          forCheckpoints: true
        }
        checkpoints: [
          {
            checkpointLabel: reply_to_topic,
            pointsPossible: 10,
            dates: [{ type: everyone, dueAt: "#{5.days.from_now.iso8601}" }]
          },
          {
            checkpointLabel: reply_to_entry,
            pointsPossible: 15,
            dates: [
              { type: everyone, dueAt: "#{10.days.from_now.iso8601}" },
              { type: override, dueAt: "#{reply_to_entry_due_at1.iso8601}", setType: CourseSection, setId: #{section1.id} },
              { type: override, dueAt: "#{reply_to_entry_due_at2.iso8601}", setType: CourseSection, setId: #{section2.id} }
            ],
            repliesRequired: 3
          }
        ]
      GQL

      result = execute_with_input_with_assignment(query)
      expect(result["errors"]).to be_nil

      assignment = Assignment.last

      expect(assignment.has_sub_assignments?).to be true

      sub_assignments = SubAssignment.where(parent_assignment_id: assignment.id)
      sub_assignment1 = sub_assignments.find_by(sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC)
      sub_assignment2 = sub_assignments.find_by(sub_assignment_tag: CheckpointLabels::REPLY_TO_ENTRY)

      expect(sub_assignment1.sub_assignment_tag).to eq "reply_to_topic"
      expect(sub_assignment1.points_possible).to eq 10
      expect(sub_assignment2.sub_assignment_tag).to eq "reply_to_entry"
      expect(sub_assignment2.points_possible).to eq 15

      assignment_override1 = AssignmentOverride.find_by(assignment: sub_assignment2, set_type: "CourseSection", set_id: section1.id)
      assignment_override2 = AssignmentOverride.find_by(assignment: sub_assignment2, set_type: "CourseSection", set_id: section2.id)

      expect(assignment_override1).to be_present
      expect(assignment_override2).to be_present
      expect(assignment_override1.due_at).to be_within(1.second).of reply_to_entry_due_at1
      expect(assignment_override2.due_at).to be_within(1.second).of reply_to_entry_due_at2
    end

    it "successfully creates a discussion topic with checkpoints and AdHoc overrides" do
      student1 = student_in_course(course: @course, active_all: true).user
      student2 = student_in_course(course: @course, active_all: true).user

      context_type = "Course"
      title = "Graded Discussion w/Checkpoints and AdHoc overrides"
      message = "Lorem ipsum..."
      published = true

      reply_to_entry_due_at = 12.days.from_now

      query = <<~GQL
        contextId: "#{@course.id}"
        contextType: #{context_type}
        title: "#{title}"
        message: "#{message}"
        published: #{published}
        assignment: {
          courseId: "#{@course.id}",
          name: "#{title}",
          forCheckpoints: true
        }
        checkpoints: [
          {
            checkpointLabel: reply_to_topic,
            pointsPossible: 10,
            dates: [{ type: everyone, dueAt: "#{5.days.from_now.iso8601}" }]
          },
          {
            checkpointLabel: reply_to_entry,
            pointsPossible: 15,
            dates: [
              { type: everyone, dueAt: "#{10.days.from_now.iso8601}" },
              { type: override, dueAt: "#{reply_to_entry_due_at.iso8601}", setType: ADHOC, studentIds: [#{student1.id}, #{student2.id}] }
            ],
            repliesRequired: 3
          }
        ]
      GQL

      result = execute_with_input_with_assignment(query)
      expect(result["errors"]).to be_nil

      assignment = Assignment.last

      expect(assignment.has_sub_assignments?).to be true

      sub_assignments = SubAssignment.where(parent_assignment_id: assignment.id)
      sub_assignment1 = sub_assignments.find_by(sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC)
      sub_assignment2 = sub_assignments.find_by(sub_assignment_tag: CheckpointLabels::REPLY_TO_ENTRY)

      expect(sub_assignment1.sub_assignment_tag).to eq "reply_to_topic"
      expect(sub_assignment1.points_possible).to eq 10
      expect(sub_assignment2.sub_assignment_tag).to eq "reply_to_entry"
      expect(sub_assignment2.points_possible).to eq 15

      assignment_override = AssignmentOverride.find_by(assignment: sub_assignment2)

      expect(assignment_override).to be_present
      expect(assignment_override.set_type).to eq "ADHOC"
      expect(assignment_override.due_at).to be_within(1.second).of reply_to_entry_due_at

      student_ids = assignment_override.assignment_override_students.pluck(:user_id)

      expect(student_ids).to match_array [student1.id, student2.id]
    end

    context "sharding" do
      specs_require_sharding

      it "successfully creates a discussion topic with checkpoints and AdHoc overrides across shards" do
        @shard1.activate do
          @student1 = user_with_pseudonym(active_user: true, username: "test1@example.com")
          @course.enroll_student(@student1, enrollment_state: "active")
        end

        @shard2.activate do
          @student2 = user_with_pseudonym(active_user: true, username: "test2@example.com")
          @course.enroll_student(@student2, enrollment_state: "active")
        end

        context_type = "Course"
        title = "Graded Discussion w/Checkpoints and AdHoc overrides"
        message = "Lorem ipsum..."
        published = true

        reply_to_entry_due_at = 12.days.from_now

        query = <<~GQL
          contextId: "#{@course.id}"
          contextType: #{context_type}
          title: "#{title}"
          message: "#{message}"
          published: #{published}
          assignment: {
            courseId: "#{@course.id}",
            name: "#{title}",
            forCheckpoints: true
          }
          checkpoints: [
            {
              checkpointLabel: reply_to_topic,
              pointsPossible: 10,
              dates: [{ type: everyone, dueAt: "#{5.days.from_now.iso8601}" }]
            },
            {
              checkpointLabel: reply_to_entry,
              pointsPossible: 15,
              dates: [
                { type: everyone, dueAt: "#{10.days.from_now.iso8601}" },
                { type: override, dueAt: "#{reply_to_entry_due_at.iso8601}", setType: ADHOC, studentIds: [#{@student1.global_id}, #{@student2.global_id}] }
              ],
              repliesRequired: 3
            }
          ]
        GQL

        result = execute_with_input_with_assignment(query)
        expect(result["errors"]).to be_nil

        assignment = Assignment.last

        expect(assignment.has_sub_assignments?).to be true

        sub_assignments = SubAssignment.where(parent_assignment_id: assignment.id)
        sub_assignment1 = sub_assignments.find_by(sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC)
        sub_assignment2 = sub_assignments.find_by(sub_assignment_tag: CheckpointLabels::REPLY_TO_ENTRY)

        expect(sub_assignment1.sub_assignment_tag).to eq "reply_to_topic"
        expect(sub_assignment1.points_possible).to eq 10
        expect(sub_assignment2.sub_assignment_tag).to eq "reply_to_entry"
        expect(sub_assignment2.points_possible).to eq 15

        assignment_override = AssignmentOverride.find_by(assignment: sub_assignment2)

        expect(assignment_override).to be_present
        expect(assignment_override.set_type).to eq "ADHOC"
        expect(assignment_override.due_at).to be_within(1.second).of reply_to_entry_due_at

        student_ids = assignment_override.assignment_override_students.map { |o| o.user.global_id }

        expect(student_ids).to match_array [@student1.global_id, @student2.global_id]
      end
    end
  end

  context "group category id" do
    it "creates parent and child dicussion topics" do
      gc = @course.group_categories.create! name: "foo"
      gc.groups.create! context: @course, name: "baz"
      context_type = "Course"
      title = "Test Title"
      message = "A message"
      published = true

      query = <<~GQL
        contextId: "#{@course.id}"
        contextType: #{context_type}
        title: "#{title}"
        message: "#{message}"
        published: #{published}
        groupCategoryId: "#{gc.id}"
      GQL

      result = execute_with_input(query)
      returned_discussion_topic = result.dig("data", "createDiscussionTopic", "discussionTopic")
      expect(result["errors"]).to be_nil
      expect(returned_discussion_topic["groupSet"]["_id"]).to eq gc.id.to_s
      discussion_topics = DiscussionTopic.last(2)
      expect(discussion_topics[0].group_category_id).to eq gc.id
      expect(discussion_topics[1].group_category_id).to eq gc.id
    end

    it "creates a checkpointed graded group discussion successfully" do
      context_type = "Course"
      title = "Graded Discussion"
      message = "Lorem ipsum..."
      published = true
      @course.enroll_student(User.create!, enrollment_state: "active").user
      group_category = @course.group_categories.create! name: "foo"

      query = <<~GQL
        contextId: "#{@course.id}"
        contextType: #{context_type}
        title: "#{title}"
        message: "#{message}"
        published: #{published}
        groupCategoryId: "#{group_category.id}"
        assignment: {
          courseId: "#{@course.id}",
          name: "#{title}",
          forCheckpoints: true,
        }
        checkpoints: [
          {
            checkpointLabel: reply_to_topic,
            pointsPossible: 10,
            dates: [{ type: everyone, dueAt: "#{5.days.from_now.iso8601}" }]
          },
          {
            checkpointLabel: reply_to_entry,
            pointsPossible: 15,
            dates: [{ type: everyone, dueAt: "#{10.days.from_now.iso8601}" }],
            repliesRequired: 3
          }
        ]
      GQL

      result = execute_with_input_with_assignment(query)
      expect(result["data"]["createDiscussionTopic"]["errors"]).to be_nil
      discussion_topic = result.dig("data", "createDiscussionTopic", "discussionTopic")
      expect(discussion_topic["assignment"]["checkpoints"].length).to eq 2
    end

    it "does not create when id is invalid" do
      context_type = "Course"
      title = "Test Title"
      message = "A message"
      published = true

      query = <<~GQL
        contextId: "#{@course.id}"
        contextType: #{context_type}
        title: "#{title}"
        message: "#{message}"
        published: #{published}
        groupCategoryId: "foo"
      GQL

      result = execute_with_input(query)
      returned_discussion_topic = result.dig("data", "createDiscussionTopic", "discussionTopic")
      expect(result["errors"]).to be_nil
      expect(returned_discussion_topic["groupSet"]).to be_nil
      discussion_topics = DiscussionTopic.last
      expect(discussion_topics.group_category_id).to be_nil
    end
  end

  context "with differentiated modules" do
    it "successfully creates a ungraded discussion topic with override" do
      context_type = "Course"
      title = "Ungraded Discussion"
      message = "Lorem ipsum..."
      published = true
      student1 = @course.enroll_student(User.create!, enrollment_state: "active").user
      student2 = @course.enroll_student(User.create!, enrollment_state: "active").user

      query = <<~GQL
        contextId: "#{@course.id}"
        contextType: #{context_type}
        title: "#{title}"
        message: "#{message}"
        published: #{published}
        ungradedDiscussionOverrides: {
          studentIds: [#{student1.id}, #{student2.id}]
        }
      GQL

      result = execute_with_input(query)
      discussion_topic = result.dig("data", "createDiscussionTopic", "discussionTopic")
      override = DiscussionTopic.last.active_assignment_overrides.first
      aggregate_failures do
        expect(result.dig("data", "discussionTopic", "errors")).to be_nil
        expect(discussion_topic["ungradedDiscussionOverrides"]["nodes"]).to match([{ "_id" => override.id.to_s, "title" => override.title }])
        expect(override.set_type).to eq("ADHOC")
        expect(override.set_id).to be_nil
        expect(override.set.map(&:id)).to match_array([student1.id, student2.id])
        expect(override.workflow_state).to eq "active"
      end
    end

    it "does not create overrides on a group discussion topic" do
      group = @course.groups.create!
      student_in_group = student_in_course(course: @course, active_all: true).user
      group.group_memberships.create!(user: student_in_group)

      context_type = "Group"
      title = "Group Discussion"
      message = "Lorem ipsum..."
      published = true

      query = <<~GQL
        contextId: "#{group.id}"
        contextType: #{context_type}
        title: "#{title}"
        message: "#{message}"
        published: #{published}
        ungradedDiscussionOverrides: {
          studentIds: [#{student_in_group.id}]
        }
      GQL

      result = execute_with_input(query)
      override = DiscussionTopic.last.active_assignment_overrides.first
      aggregate_failures do
        expect(result.dig("data", "discussionTopic", "errors")).to be_nil
        expect(override).to be_nil
      end
    end
  end

  it "default sort order is correct" do
    context_type = "Course"
    title = "Test Title"
    message = "A message"
    published = false
    require_initial_post = true

    query = <<~GQL
      contextId: "#{@course.id}"
      contextType: #{context_type}
      title: "#{title}"
      message: "#{message}"
      published: #{published}
      requireInitialPost: #{require_initial_post}
      sortOrder: asc
    GQL

    result = execute_with_input(query)
    created_discussion_topic = result.dig("data", "createDiscussionTopic", "discussionTopic")

    expect(result["errors"]).to be_nil
    expect(result.dig("data", "discussionTopic", "errors")).to be_nil
    expect(created_discussion_topic["sortOrder"]).to eq DiscussionTopic::SortOrder::ASC
  end

  context "discussion_default_expand and discussion_default_sort" do
    it "cannot create discussion with default_expand = false and default_expand_locked = true" do
      context_type = "Course"
      title = "Test Title"
      message = "A message"
      published = false
      expanded = false
      expanded_locked = true

      query = <<~GQL
        contextId: "#{@course.id}"
        contextType: #{context_type}
        title: "#{title}"
        message: "#{message}"
        published: #{published}
        expanded: #{expanded}
        expandedLocked: #{expanded_locked}
      GQL

      result = execute_with_input(query)
      result = result.dig("data", "createDiscussionTopic")
      expect(result["errors"][0]["message"]).to match(/Cannot set default thread state locked, when threads are collapsed/)
    end
  end
end
