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

RSpec.describe Mutations::UpdateDiscussionEntry do
  before(:once) do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
    discussion_topic_model({ context: @course })
    @attachment = attachment_with_context(@student)
    @entry = @topic.discussion_entries.create!(message: "Howdy", user: @student, attachment: @attachment)
    @topic.update!(discussion_type: "threaded")
  end

  def mutation_str(
    discussion_entry_id: nil,
    message: nil,
    remove_attachment: nil,
    file_id: nil,
    quoted_entry_id: nil
  )
    <<~GQL
      mutation {
        updateDiscussionEntry(input: {
          discussionEntryId: #{discussion_entry_id}
          #{"message: \"#{message}\"" unless message.nil?}
          #{"removeAttachment: #{remove_attachment}" unless remove_attachment.nil?}
          #{"fileId: #{file_id}" unless file_id.nil?}
          #{"quotedEntryId: #{quoted_entry_id}" unless quoted_entry_id.nil?}
        }) {
          discussionEntry {
            _id
            message
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

  it "updates a discussion entry message" do
    result = run_mutation(discussion_entry_id: @entry.id, message: "New message")
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateDiscussionEntry", "errors")).to be_nil
    expect(result.dig("data", "updateDiscussionEntry", "discussionEntry", "message")).to eq "New message"
    expect(@entry.reload.message).to eq "New message"
  end

  it "deletes discussion_entry_drafts for an edit" do
    delete_me = DiscussionEntryDraft.upsert_draft(user: @student, topic: @topic, message: "Howdy Hey", entry: @entry)
    run_mutation(discussion_entry_id: @entry.id, message: "New message")
    expect(DiscussionEntryDraft.where(id: delete_me)).to eq []
  end

  it "deletes discussion_entry_drafts for an edit for a non author" do
    delete_me = DiscussionEntryDraft.upsert_draft(user: @teacher, topic: @topic, message: "talk to me", entry: @entry)
    keeper = DiscussionEntryDraft.upsert_draft(user: @student, topic: @topic, message: "Howdy Hey", entry: @entry)
    run_mutation({ discussion_entry_id: @entry.id, message: "New message" }, @teacher)
    expect(DiscussionEntryDraft.where(id: [delete_me, keeper].flatten).pluck(:id)).to eq keeper
  end

  it "removes a discussion entry attachment" do
    result = run_mutation(discussion_entry_id: @entry.id, remove_attachment: true)
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateDiscussionEntry", "errors")).to be_nil
    expect(result.dig("data", "updateDiscussionEntry", "discussionEntry", "attachment")).to be_nil
    expect(@entry.reload.attachment).to be_nil
  end

  it "replaces a discussion entry attachment" do
    attachment = attachment_with_context(@student)
    attachment.update!(user: @student)
    result = run_mutation(discussion_entry_id: @entry.id, file_id: attachment.id)
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateDiscussionEntry", "errors")).to be_nil
    expect(result.dig("data", "updateDiscussionEntry", "discussionEntry", "attachment", "_id")).to eq attachment.id.to_s
    expect(@entry.reload.attachment_id).to eq attachment.id
  end

  it "allows students to update discussion entry even without allow_student_forum_attachments permission" do
    new_message = "updated banana"
    @course.update!(allow_student_forum_attachments: false)
    result = run_mutation({ discussion_entry_id: @entry.id, remove_attachment: true, message: new_message }, @student)
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateDiscussionEntry", "errors")).to be_nil
    expect(@entry.reload.message).to eq new_message
  end

  it "allows teachers to update discussion entry even without allow_student_forum_attachments permission" do
    new_message = "updated banana"
    @course.update!(allow_student_forum_attachments: false)
    result = run_mutation({ discussion_entry_id: @entry.id, remove_attachment: true, message: new_message }, @teacher)
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateDiscussionEntry", "errors")).to be_nil
    expect(@entry.reload.message).to eq new_message
  end

  it "allows teachers to edit post with student attachment" do
    attachment = attachment_with_context(@student)
    attachment.update!(user: @student)
    @entry.attachment = attachment
    @entry.save

    # Update message as a teacher
    result = run_mutation({ discussion_entry_id: @entry.id, file_id: attachment.id, message: "edit student entry without touching file_id" }, @teacher)

    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateDiscussionEntry", "errors")).to be_nil
    expect(result.dig("data", "updateDiscussionEntry", "discussionEntry", "attachment", "_id")).to eq attachment.id.to_s
    expect(@entry.reload.attachment_id).to eq attachment.id
    # Verify that the owner of the attachment did not change when teacher edited message
    expect(@entry.reload.attachment.user.id).to eq @student.id
  end

  context "quoted entry id" do
    it "cannot be true on a root entry" do
      result = run_mutation(discussion_entry_id: @entry.id, quoted_entry_id: 9)
      expect(result["errors"]).to be_nil
      expect(result.dig("data", "updateDiscussionEntry", "errors")).to be_nil
      expect(@entry.reload.quoted_entry_id).to be_nil
    end

    it "can be true on a reply to a root entry" do
      parent_entry = @topic.discussion_entries.create!(message: "I am the parent reply", user: @student, attachment: @attachment)
      entry = @topic.discussion_entries.create!(message: "I am the child reply", user: @student, attachment: @attachment, parent_id: parent_entry.id, quoted_entry_id: parent_entry.id, root_entry_id: parent_entry.id)
      result = run_mutation(discussion_entry_id: entry.id, quoted_entry_id: parent_entry.id)
      expect(result["errors"]).to be_nil
      expect(result.dig("data", "updateDiscussionEntry", "errors")).to be_nil
      expect(entry.reload.quoted_entry_id).to be parent_entry.id
    end

    it "does set on reply to a child reply" do
      parent_entry = @topic.discussion_entries.create!(message: "I am the parent reply", user: @student, attachment: @attachment)
      child_reply = @topic.discussion_entries.create!(message: "I am the child reply", user: @student, attachment: @attachment, parent_id: parent_entry.id)
      entry = @topic.discussion_entries.create!(message: "Howdy", user: @student, attachment: @attachment, parent_id: child_reply.id, quoted_entry_id: nil)
      result = run_mutation(discussion_entry_id: entry.id, quoted_entry_id: parent_entry.id)
      expect(result["errors"]).to be_nil
      expect(result.dig("data",
                        'updateDiscussion
        Entry',
                        "errors")).to be_nil
      expect(entry.reload.quoted_entry_id).to be parent_entry.id
    end

    it "allows removing quoted entry id" do
      parent_entry = @topic.discussion_entries.create!(message: "I am the parent reply", user: @student, attachment: @attachment)
      child_reply = @topic.discussion_entries.create!(message: "I am the child reply", user: @student, attachment: @attachment, parent_id: parent_entry.id)
      entry = @topic.discussion_entries.create!(message: "Howdy", user: @student, attachment: @attachment, parent_id: child_reply.id, quoted_entry_id: parent_entry.id)
      expect(entry.reload.quoted_entry_id).to be parent_entry.id
      run_mutation(discussion_entry_id: entry.id, quoted_entry_id: nil)
      expect(entry.reload.quoted_entry_id).to be_nil
    end
  end

  context "errors" do
    it "if given a bad discussion entry id" do
      result = run_mutation(discussion_entry_id: @entry.id + 1337, message: "should fail")
      expect(result.dig("data", "updateDiscussionEntry")).to be_nil
      expect(result.dig("errors", 0, "message")).to eq "not found"
    end

    it "if the user does not have permission to read" do
      user = user_model
      result = run_mutation({ discussion_entry_id: @entry.id, message: "should fail" }, user)
      expect(result.dig("data", "updateDiscussionEntry")).to be_nil
      expect(result.dig("errors", 0, "message")).to eq "not found"
    end

    it "if the user does not have permission to update" do
      entry = @topic.discussion_entries.create!(message: "teacher message", user: @teacher)
      result = run_mutation({ discussion_entry_id: entry.id, message: "should fail" }, @student)
      expect(result.dig("data", "updateDiscussionEntry", "discussionEntry")).to be_nil
      expect(result.dig("data", "updateDiscussionEntry", "errors", 0, "message")).to eq "Insufficient Permissions"
    end

    it "if given a bad attachment id" do
      result = run_mutation(discussion_entry_id: @entry.id, file_id: @attachment.id + 1337)
      expect(result.dig("data", "updateDiscussionEntry")).to be_nil
      expect(result.dig("errors", 0, "message")).to eq "not found"
    end

    it "if the user does not own the attachment" do
      attachment = attachment_with_context(@teacher)
      attachment.update!(user: @teacher)
      result = run_mutation(discussion_entry_id: @entry.id, file_id: attachment.id)
      expect(result.dig("data", "updateDiscussionEntry")).to be_nil
      expect(result.dig("errors", 0, "message")).to eq "not found"
    end

    it "returns validation_error when user does not have attach permissions" do
      current_attachment_id = @entry.attachment_id
      attachment = attachment_with_context(@student)
      attachment.update!(user: @student)
      @course.update!(allow_student_forum_attachments: false)

      result = run_mutation(discussion_entry_id: @entry.id, file_id: attachment.id)
      expect(result["errors"]).to be_nil
      expect(result.dig("data", "updateDiscussionEntry", "errors", 0, "message")).to eq "Insufficient attach permissions"
      expect(result.dig("data", "updateDiscussionEntry", "discussionEntry", "attachment", "_id")).to be_nil
      expect(@entry.reload.attachment_id).to eq current_attachment_id
    end
  end
end
