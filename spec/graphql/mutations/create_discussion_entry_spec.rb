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
    discussion_topic_model({ context: @course, discussion_type: DiscussionTopic::DiscussionTypes::THREADED })
  end

  def mutation_str(
    discussion_topic_id: nil,
    message: nil,
    parent_entry_id: nil,
    file_id: nil,
    include_reply_preview: nil,
    is_anonymous_author: nil
  )
    <<~GQL
      mutation {
        createDiscussionEntry(input: {
          discussionTopicId: #{discussion_topic_id}
          message: "#{message}"
          #{"parentEntryId: #{parent_entry_id}" unless parent_entry_id.nil?}
          #{"fileId: #{file_id}" unless file_id.nil?}
          #{"includeReplyPreview: #{include_reply_preview}" unless include_reply_preview.nil?}
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
        current_user: current_user,
        request: ActionDispatch::TestRequest.create
      }
    )
    result.to_h.with_indifferent_access
  end

  it "creates a discussion entry" do
    result = run_mutation(discussion_topic_id: @topic.id, message: "Howdy Hey")
    expect(result["errors"]).to be nil
    expect(result.dig("data", "createDiscussionEntry", "errors")).to be nil

    entry = @topic.discussion_entries.last
    expect(result.dig("data", "createDiscussionEntry", "discussionEntry", "_id")).to eq entry.id.to_s
    expect(result.dig("data", "createDiscussionEntry", "discussionEntry", "message")).to eq entry.message
  end

  it "creates a discussion entry with anonymous author" do
    result = run_mutation(discussion_topic_id: @topic.id, message: "Howdy Hey", is_anonymous_author: true)
    expect(result["errors"]).to be nil
    expect(result.dig("data", "createDiscussionEntry", "errors")).to be nil

    entry = @topic.discussion_entries.last
    expect(result.dig("data", "createDiscussionEntry", "discussionEntry", "_id")).to eq entry.id.to_s
    expect(result.dig("data", "createDiscussionEntry", "discussionEntry", "message")).to eq entry.message
    expect(entry.is_anonymous_author).to eq true
  end

  it "deletes discussion_entry_drafts on create" do
    draft_id = DiscussionEntryDraft.upsert_draft(user: @student, topic: @topic, message: "Howdy Hey")
    run_mutation(discussion_topic_id: @topic.id, message: "Howdy Hey")
    expect(DiscussionEntryDraft.where(id: draft_id)).to eq []
  end

  it "deletes discussion_entry_drafts on create for the correct entry" do
    parent = @topic.discussion_entries.create!(message: "parent entry", user: @teacher, discussion_topic: @topic)

    keeper = DiscussionEntryDraft.upsert_draft(user: @student, topic: @topic, message: "Howdy Hey")
    DiscussionEntryDraft.upsert_draft(user: @student, topic: @topic, parent: parent, message: "delete_me")
    run_mutation(discussion_topic_id: @topic.id, message: "child entry", parent_entry_id: parent.id)
    expect(DiscussionEntryDraft.where(discussion_topic_id: @topic).pluck(:id)).to eq keeper
  end

  it "replies to an existing discussion entry" do
    parent_entry = @topic.discussion_entries.create!(message: "parent entry", user: @teacher, discussion_topic: @topic)
    result = run_mutation(discussion_topic_id: @topic.id, message: "child entry", parent_entry_id: parent_entry.id)
    expect(result["errors"]).to be nil
    expect(result.dig("data", "createDiscussionEntry", "errors")).to be nil

    entry = @topic.discussion_entries.last
    expect(result.dig("data", "createDiscussionEntry", "discussionEntry", "_id")).to eq entry.id.to_s
    expect(result.dig("data", "createDiscussionEntry", "discussionEntry", "message")).to eq entry.message
    expect(result.dig("data", "createDiscussionEntry", "discussionEntry", "parentId")).to eq parent_entry.id.to_s
  end

  it "replies to an existing discussion child entry" do
    root_entry = @topic.discussion_entries.create!(message: "root entry", user: @teacher, discussion_topic: @topic)
    parent_entry = @topic.discussion_entries.create!(message: "parent entry", user: @teacher, discussion_topic: @topic, parent_entry: root_entry)
    result = run_mutation(discussion_topic_id: @topic.id, message: "child entry", parent_entry_id: parent_entry.id)
    expect(result["errors"]).to be nil
    expect(result.dig("data", "createDiscussionEntry", "errors")).to be nil

    entry = @topic.discussion_entries.last
    expect(result.dig("data", "createDiscussionEntry", "discussionEntry", "_id")).to eq entry.id.to_s
    expect(result.dig("data", "createDiscussionEntry", "discussionEntry", "message")).to eq entry.message
    expect(result.dig("data", "createDiscussionEntry", "discussionEntry", "parentId")).to eq parent_entry.id.to_s
    expect(entry.root_entry_id).to eq root_entry.id
    expect(entry.include_reply_preview?).to be false
  end

  it "adds an attachment when creating a discussion entry" do
    attachment = attachment_with_context(@student)
    attachment.update!(user: @student)
    result = run_mutation(discussion_topic_id: @topic.id, message: "howdy", file_id: attachment.id)
    expect(result["errors"]).to be nil
    expect(result.dig("data", "createDiscussionEntry", "errors")).to be nil

    entry = @topic.discussion_entries.last
    expect(result.dig("data", "createDiscussionEntry", "discussionEntry", "attachment", "_id")).to eq attachment.id.to_s
    expect(entry.reload.attachment_id).to eq attachment.id
  end

  context "include reply preview" do
    it "cannot be a root entry" do
      result = run_mutation(discussion_topic_id: @topic.id, message: "Howdy Hey", include_reply_preview: true)
      expect(result["errors"]).to be nil
      expect(result.dig("data", "createDiscussionEntry", "errors")).to be nil

      entry = @topic.discussion_entries.last
      expect(entry.include_reply_preview?).to be false
    end

    it "can be a reply to a root entry" do
      root_entry = @topic.discussion_entries.create!(message: "parent entry", user: @teacher, discussion_topic: @topic)
      result = run_mutation(discussion_topic_id: @topic.id, message: "Howdy Hey", include_reply_preview: true, parent_entry_id: root_entry.id)

      expect(result["errors"]).to be nil
      expect(result.dig("data", "createDiscussionEntry", "errors")).to be nil

      entry = @topic.discussion_entries.last
      expect(entry.include_reply_preview?).to be true
    end

    it "does set on reply to a child reply" do
      root_entry = @topic.discussion_entries.create!(message: "root entry", user: @teacher, discussion_topic: @topic)
      parent_entry = @topic.discussion_entries.create!(message: "parent entry", user: @teacher, discussion_topic: @topic, parent_entry: root_entry)
      run_mutation(discussion_topic_id: @topic.id, message: "child entry", parent_entry_id: parent_entry.id, include_reply_preview: true)

      entry = @topic.discussion_entries.last
      expect(entry.include_reply_preview?).to be true
    end

    it "allows creating with include reply preview as false" do
      root_entry = @topic.discussion_entries.create!(message: "root entry", user: @teacher, discussion_topic: @topic)
      parent_entry = @topic.discussion_entries.create!(message: "parent entry", user: @teacher, discussion_topic: @topic, parent_entry: root_entry)
      run_mutation(discussion_topic_id: @topic.id, message: "child entry", parent_entry_id: parent_entry.id, include_reply_preview: false)

      entry = @topic.discussion_entries.last
      expect(entry.include_reply_preview?).to be false
    end
  end

  context "errors" do
    it "if given a bad discussion topic id" do
      result = run_mutation(discussion_topic_id: @topic.id + 1337, message: "this should fail")
      expect(result.dig("data", "createDiscussionEntry")).to be nil
      expect(result.dig("errors", 0, "message")).to eq "not found"
    end

    it "if the user does not have permission to read" do
      user = user_model
      result = run_mutation({ discussion_topic_id: @topic.id, message: "this should fail" }, user)
      expect(result.dig("data", "createDiscussionEntry")).to be nil
      expect(result.dig("errors", 0, "message")).to eq "not found"
    end

    it "if given a bad attachment id" do
      result = run_mutation(discussion_topic_id: @topic.id, message: "this should fail", file_id: 1337)
      expect(result.dig("data", "createDiscussionEntry")).to be nil
      expect(result.dig("errors", 0, "message")).to eq "not found"
    end

    it "if the user does not own the attachment" do
      attachment = attachment_with_context(@teacher)
      attachment.update!(user: @teacher)
      result = run_mutation(discussion_topic_id: @topic.id, message: "this should fail", file_id: attachment.id)
      expect(result.dig("data", "createDiscussionEntry")).to be nil
      expect(result.dig("errors", 0, "message")).to eq "not found"
    end
  end
end
