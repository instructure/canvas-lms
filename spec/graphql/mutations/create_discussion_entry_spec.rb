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

require_relative "../graphql_spec_helper"

RSpec.describe Mutations::CreateDiscussionEntry do
  before(:once) do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
    teacher_in_course(active_all: true)
    discussion_topic_model({ context: @course, discussion_type: DiscussionTopic::DiscussionTypes::THREADED })
  end

  def mutation_str(
    discussion_topic_id: nil,
    message: nil,
    parent_entry_id: nil,
    file_id: nil,
    is_anonymous_author: nil,
    quoted_entry_id: nil
  )
    <<~GQL
      mutation {
        createDiscussionEntry(input: {
          discussionTopicId: #{discussion_topic_id}
          message: "#{message}"
          #{"parentEntryId: #{parent_entry_id}" unless parent_entry_id.nil?}
          #{"fileId: #{file_id}" unless file_id.nil?}
          #{"quotedEntryId: #{quoted_entry_id}" unless quoted_entry_id.nil?}
          #{"isAnonymousAuthor: #{is_anonymous_author}" unless is_anonymous_author.nil?}
          }) {
          discussionEntry {
            _id
            message
            parentId
            attachment {
              _id
            }
          }
          errors {
            message
            attribute
          }
        }
      }
    GQL
  end

  def run_mutation(opts = {}, current_user = @student)
    result = CanvasSchema.execute(
      mutation_str(**opts),
      context: {
        current_user:,
        request: ActionDispatch::TestRequest.create
      }
    )
    result.to_h.with_indifferent_access
  end

  it "creates a discussion entry" do
    result = run_mutation(discussion_topic_id: @topic.id, message: "Howdy Hey")
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "createDiscussionEntry", "errors")).to be_nil

    entry = @topic.discussion_entries.last
    expect(result.dig("data", "createDiscussionEntry", "discussionEntry", "_id")).to eq entry.id.to_s
    expect(result.dig("data", "createDiscussionEntry", "discussionEntry", "message")).to eq entry.message
  end

  it "creates a discussion entry with anonymous author" do
    result = run_mutation(discussion_topic_id: @topic.id, message: "Howdy Hey", is_anonymous_author: true)
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "createDiscussionEntry", "errors")).to be_nil

    entry = @topic.discussion_entries.last
    expect(result.dig("data", "createDiscussionEntry", "discussionEntry", "_id")).to eq entry.id.to_s
    expect(result.dig("data", "createDiscussionEntry", "discussionEntry", "message")).to eq entry.message
    expect(entry.is_anonymous_author).to be true
  end

  it "deletes discussion_entry_drafts on create" do
    draft_id = DiscussionEntryDraft.upsert_draft(user: @student, topic: @topic, message: "Howdy Hey")
    run_mutation(discussion_topic_id: @topic.id, message: "Howdy Hey")
    expect(DiscussionEntryDraft.where(id: draft_id)).to eq []
  end

  it "deletes discussion_entry_drafts on create for the correct entry" do
    parent = @topic.discussion_entries.create!(message: "parent entry", user: @teacher, discussion_topic: @topic)

    keeper = DiscussionEntryDraft.upsert_draft(user: @student, topic: @topic, message: "Howdy Hey")
    DiscussionEntryDraft.upsert_draft(user: @student, topic: @topic, parent:, message: "delete_me")
    run_mutation(discussion_topic_id: @topic.id, message: "child entry", parent_entry_id: parent.id)
    expect(DiscussionEntryDraft.where(discussion_topic_id: @topic).pluck(:id)).to eq keeper
  end

  it "replies to an existing discussion entry" do
    parent_entry = @topic.discussion_entries.create!(message: "parent entry", user: @teacher, discussion_topic: @topic)
    result = run_mutation(discussion_topic_id: @topic.id, message: "child entry", parent_entry_id: parent_entry.id)
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "createDiscussionEntry", "errors")).to be_nil

    entry = @topic.discussion_entries.last
    expect(result.dig("data", "createDiscussionEntry", "discussionEntry", "_id")).to eq entry.id.to_s
    expect(result.dig("data", "createDiscussionEntry", "discussionEntry", "message")).to eq entry.message
    expect(result.dig("data", "createDiscussionEntry", "discussionEntry", "parentId")).to eq parent_entry.id.to_s
  end

  it "replies to an existing discussion child entry" do
    root_entry = @topic.discussion_entries.create!(message: "root entry", user: @teacher, discussion_topic: @topic)
    parent_entry = @topic.discussion_entries.create!(message: "parent entry", user: @teacher, discussion_topic: @topic, parent_entry: root_entry)
    result = run_mutation(discussion_topic_id: @topic.id, message: "child entry", parent_entry_id: parent_entry.id)
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "createDiscussionEntry", "errors")).to be_nil

    entry = @topic.discussion_entries.last
    expect(result.dig("data", "createDiscussionEntry", "discussionEntry", "_id")).to eq entry.id.to_s
    expect(result.dig("data", "createDiscussionEntry", "discussionEntry", "message")).to eq entry.message
    expect(result.dig("data", "createDiscussionEntry", "discussionEntry", "parentId")).to eq parent_entry.id.to_s
    expect(entry.root_entry_id).to eq root_entry.id
  end

  it "adds an attachment when creating a discussion entry" do
    attachment = attachment_with_context(@student)
    attachment.update!(user: @student)
    result = run_mutation(discussion_topic_id: @topic.id, message: "howdy", file_id: attachment.id)
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "createDiscussionEntry", "errors")).to be_nil

    entry = @topic.discussion_entries.last
    expect(result.dig("data", "createDiscussionEntry", "discussionEntry", "attachment", "_id")).to eq attachment.id.to_s
    expect(entry.reload.attachment_id).to eq attachment.id
  end

  it "allows teachers to attach even with allow_student_forum_attachments set to false" do
    @course.update!(allow_student_forum_attachments: false)
    attachment = attachment_with_context(@teacher)
    attachment.update!(user: @teacher)
    result = run_mutation({ discussion_topic_id: @topic.id, message: "howdy", file_id: attachment.id }, @teacher)
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "createDiscussionEntry", "errors")).to be_nil

    entry = @topic.discussion_entries.last
    expect(result.dig("data", "createDiscussionEntry", "discussionEntry", "attachment", "_id")).to eq attachment.id.to_s
    expect(entry.reload.attachment_id).to eq attachment.id
  end

  context "when :discussion_checkpoints is enabled" do
    before do
      Account.default.enable_feature!(:discussion_checkpoints)
      @topic = DiscussionTopic.create_graded_topic!(course: @course, title: "Checkpointed Discussion")
      @topic.reply_to_entry_required_count = 2
      @topic.save!
      @assignment = @topic.assignment
      @assignment.update!(has_sub_assignments: true)
      @assignment.sub_assignments.create!(context: @course, sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC, points_possible: 5, due_at: 3.days.from_now)
      @assignment.sub_assignments.create!(context: @course, sub_assignment_tag: CheckpointLabels::REPLY_TO_ENTRY, points_possible: 10, due_at: 5.days.from_now)
    end

    context "mySubAssignmentSubmissions" do
      def checkpoints_mutation_str(
        discussion_topic_id: nil,
        message: nil,
        parent_entry_id: nil,
        file_id: nil,
        is_anonymous_author: nil,
        quoted_entry_id: nil
      )
        <<~GQL
          mutation {
            createDiscussionEntry(input: {
              discussionTopicId: #{discussion_topic_id}
              message: "#{message}"
              #{"parentEntryId: #{parent_entry_id}" unless parent_entry_id.nil?}
              #{"fileId: #{file_id}" unless file_id.nil?}
              #{"quotedEntryId: #{quoted_entry_id}" unless quoted_entry_id.nil?}
              #{"isAnonymousAuthor: #{is_anonymous_author}" unless is_anonymous_author.nil?}
              }) {
              discussionEntry {
                _id
                message
                parentId
                attachment {
                  _id
                }
              }
              mySubAssignmentSubmissions {
                _id
                submissionStatus
                subAssignmentTag
                submittedAt
              }
              errors {
                message
                attribute
              }
            }
          }
        GQL
      end

      def run_checkpoints_mutation(opts = {}, current_user = @student)
        result = CanvasSchema.execute(
          checkpoints_mutation_str(**opts),
          context: {
            current_user:,
            request: ActionDispatch::TestRequest.create
          }
        )
        result.to_h.with_indifferent_access
      end

      it "returns empty array for teachers" do
        result = run_checkpoints_mutation({ discussion_topic_id: @topic.id, message: "my root reply" }, @teacher)
        expect(result["errors"]).to be_nil
        expect(result.dig("data", "createDiscussionEntry", "errors")).to be_nil
        my_assignment_submissions = result.dig("data", "createDiscussionEntry", "mySubAssignmentSubmissions")
        expect(my_assignment_submissions).to be_empty
      end

      it "returns mySubAssignmentSubmissions data for student root replies for checkpointed discussions" do
        result = run_checkpoints_mutation(discussion_topic_id: @topic.id, message: "my root reply")
        expect(result["errors"]).to be_nil
        expect(result.dig("data", "createDiscussionEntry", "errors")).to be_nil
        my_assignment_submissions = result.dig("data", "createDiscussionEntry", "mySubAssignmentSubmissions")
        expect(my_assignment_submissions.size).to eq 2
        reply_to_topic_submission = my_assignment_submissions.find { |s| s["subAssignmentTag"] == CheckpointLabels::REPLY_TO_TOPIC }
        reply_to_entry_submission = my_assignment_submissions.find { |s| s["subAssignmentTag"] == CheckpointLabels::REPLY_TO_ENTRY }
        expect(reply_to_topic_submission["submissionStatus"]).to eq "submitted"
        expect(reply_to_entry_submission["submissionStatus"]).to eq "unsubmitted"
      end

      it "returns reply_to_entry as submitted when student has met the required count" do
        root_entry = @topic.discussion_entries.create!(message: "root entry", user: @student, discussion_topic: @topic)
        @topic.discussion_entries.create!(message: "first child entry", user: @student, discussion_topic: @topic, parent_entry: root_entry)

        result = run_checkpoints_mutation(discussion_topic_id: @topic.id, message: "my third child entry", parent_entry_id: root_entry.id)
        expect(result.dig("data", "createDiscussionEntry", "errors")).to be_nil
        my_assignment_submissions = result.dig("data", "createDiscussionEntry", "mySubAssignmentSubmissions")
        reply_to_entry_submission = my_assignment_submissions.find { |s| s["subAssignmentTag"] == CheckpointLabels::REPLY_TO_ENTRY }
        expect(reply_to_entry_submission["submissionStatus"]).to eq "submitted"
      end
    end
  end

  context "quoted entry Id" do
    it "correctly sets the quoted_entry" do
      parent_entry = @topic.discussion_entries.create!(message: "parent entry", user: @teacher, discussion_topic: @topic)
      entry = @topic.discussion_entries.create!(message: "different", user: @teacher, discussion_topic: @topic)

      result = run_mutation(discussion_topic_id: @topic.id, message: "Howdy Hey", quoted_entry_id: entry.id, parent_entry_id: parent_entry.id)

      expect(result["errors"]).to be_nil
      expect(result.dig("data", "createDiscussionEntry", "errors")).to be_nil

      new_entry = @topic.discussion_entries.last
      expect(new_entry.quoted_entry_id).to eq entry.id
      expect(new_entry.parent_id).to eq parent_entry.id
    end
  end

  context "errors" do
    it "if given a bad quoted_entry_id" do
      result = run_mutation(discussion_topic_id: @topic.id, message: "This should fail", quoted_entry_id: 0)
      expect(result.dig("data", "createDiscussionEntry")).to be_nil
      expect(result.dig("errors", 0, "message")).to eq "not found"
    end

    it "if given a bad discussion topic id" do
      result = run_mutation(discussion_topic_id: @topic.id + 1337, message: "this should fail")
      expect(result.dig("data", "createDiscussionEntry")).to be_nil
      expect(result.dig("errors", 0, "message")).to eq "not found"
    end

    it "if the user does not have permission to read" do
      user = user_model
      result = run_mutation({ discussion_topic_id: @topic.id, message: "this should fail" }, user)
      expect(result.dig("data", "createDiscussionEntry")).to be_nil
      expect(result.dig("errors", 0, "message")).to eq "not found"
    end

    it "if given a bad attachment id" do
      result = run_mutation(discussion_topic_id: @topic.id, message: "this should fail", file_id: 1337)
      expect(result.dig("data", "createDiscussionEntry")).to be_nil
      expect(result.dig("errors", 0, "message")).to eq "not found"
    end

    it "if the user does not own the attachment" do
      attachment = attachment_with_context(@teacher)
      attachment.update!(user: @teacher)
      result = run_mutation(discussion_topic_id: @topic.id, message: "this should fail", file_id: attachment.id)
      expect(result.dig("data", "createDiscussionEntry")).to be_nil
      expect(result.dig("errors", 0, "message")).to eq "not found"
    end

    it "returns validation_error when user cannot attach" do
      attachment = attachment_with_context(@student)
      attachment.update!(user: @student)
      @course.update!(allow_student_forum_attachments: false)
      result = run_mutation(discussion_topic_id: @topic.id, message: "howdy", file_id: attachment.id)
      expect(result.dig("data", "createDiscussionEntry", "discussionEntry")).to be_nil
      expect(result.dig("data", "createDiscussionEntry", "errors", 0, "message")).to eq "Insufficient attach permissions"
    end
  end
end
