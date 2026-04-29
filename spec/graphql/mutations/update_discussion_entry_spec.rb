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
    quoted_entry_id: nil,
    pin_type: nil
  )
    <<~GQL
      mutation {
        updateDiscussionEntry(input: {
          discussionEntryId: #{discussion_entry_id}
          #{"message: \"#{message}\"" unless message.nil?}
          #{"removeAttachment: #{remove_attachment}" unless remove_attachment.nil?}
          #{"fileId: #{file_id}" unless file_id.nil?}
          #{"quotedEntryId: #{quoted_entry_id}" unless quoted_entry_id.nil?}
          #{"pinType: #{pin_type}" unless pin_type.nil?}
        }) {
          discussionEntry {
            _id
            message
            pinType
            pinnedBy {
              _id
            }
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

  it "sanitizes the entry message" do
    message = "<script>alert('hi')</script><style>button { color: white !important; }</style><p>Howdy</p>"
    result = run_mutation(discussion_entry_id: @entry.id, message:)
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateDiscussionEntry", "errors")).to be_nil
    expect(result.dig("data", "updateDiscussionEntry", "discussionEntry", "message")).to eq("<p>Howdy</p>")
    expect(@entry.reload.message).to eq "<p>Howdy</p>"
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

  describe "pin_type functionality" do
    it "allows teachers to pin a discussion entry" do
      result = run_mutation({ discussion_entry_id: @entry.id, pin_type: "thread" }, @teacher)
      expect(result["errors"]).to be_nil
      expect(result.dig("data", "updateDiscussionEntry", "errors")).to be_nil
      expect(result.dig("data", "updateDiscussionEntry", "discussionEntry", "pinType")).to eq "thread"
      expect(@entry.reload.pin_type).to eq "thread"
      expect(@entry.pinned_by).to eq @teacher
    end

    it "allows teachers to unpin a discussion entry" do
      @entry.update!(pin_type: "thread", pinned_by: @teacher)

      result = run_mutation({ discussion_entry_id: @entry.id, pin_type: "none" }, @teacher)
      expect(result["errors"]).to be_nil
      expect(result.dig("data", "updateDiscussionEntry", "errors")).to be_nil
      expect(result.dig("data", "updateDiscussionEntry", "discussionEntry", "pinType")).to be_nil
      expect(@entry.reload.pin_type).to be_nil
      expect(@entry.pinned_by).to be_nil
    end

    it "does not allow students to pin discussion entries" do
      result = run_mutation({ discussion_entry_id: @entry.id, pin_type: "reply" }, @student)
      expect(result.dig("data", "updateDiscussionEntry", "errors")).not_to be_nil
      expect(result.dig("data", "updateDiscussionEntry", "errors", 0, "message")).to include("Insufficient pin permissions")
    end
  end

  context "LTI asset processor notifications" do
    before(:once) do
      @graded_topic = DiscussionTopic.create_graded_topic!(course: @course, title: "Graded Discussion")
      @graded_entry = @graded_topic.discussion_entries.create!(message: "Original message", user: @student)
    end

    it "calls notify_asset_processors_of_discussion for graded discussion updates" do
      expect(Lti::AssetProcessorDiscussionNotifier).to receive(:notify_asset_processors_of_discussion)

      run_mutation(discussion_entry_id: @graded_entry.id, message: "Updated message")
    end
  end
end
