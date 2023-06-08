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

RSpec.describe Mutations::CreateDiscussionEntryDraft do
  before(:once) do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
    discussion_topic_model({ context: @course, discussion_type: DiscussionTopic::DiscussionTypes::THREADED })
  end

  let(:root) { @topic.discussion_entries.create!(message: "root entry", user: @teacher, discussion_topic: @topic) }
  let(:parent) { @topic.discussion_entries.create!(message: "parent_entry", parent_id: root.id, user: @teacher) }
  let(:sub) { @topic.discussion_entries.create!(message: "sub_entry", parent_id: parent.id, user: @teacher) }

  def mutation_str(
    discussion_topic_id: nil,
    discussion_entry_id: nil,
    message: nil,
    parent_entry_id: nil,
    file_id: nil,
    include_reply_preview: nil
  )
    <<~GQL
      mutation {
        createDiscussionEntryDraft(input: {
          discussionTopicId: #{discussion_topic_id}
          message: "#{message}"
          #{"parentId: #{parent_entry_id}" unless parent_entry_id.nil?}
          #{"discussionEntryId: #{discussion_entry_id}" unless discussion_entry_id.nil?}
          #{"fileId: #{file_id}" unless file_id.nil?}
          #{"includeReplyPreview: #{include_reply_preview}" unless include_reply_preview.nil?}
         }) {
          discussionEntryDraft {
            _id
            message
            parentId
          }
          errors {
            message
            attribute
          }
        }
      }
    GQL
  end

  def run_mutation(opts = {}, current_user = @teacher)
    result = CanvasSchema.execute(
      mutation_str(**opts),
      context: {
        current_user:,
        request: ActionDispatch::TestRequest.create
      }
    )
    result.to_h.with_indifferent_access
  end

  it "creates a discussion entry draft" do
    result = run_mutation(discussion_topic_id: @topic.id, message: "Howdy Hey")
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "createDiscussionEntryDraft", "errors")).to be_nil

    draft = @topic.discussion_entry_drafts.last
    expect(draft.message).to eq "Howdy Hey"
  end

  it "updates an existing discussion entry draft" do
    draft_id = DiscussionEntryDraft.upsert_draft(user: @teacher, topic: @topic, message: "hello").first
    result = run_mutation(discussion_topic_id: @topic.id, message: "hello entry")
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "createDiscussionEntryDraft", "discussionEntryDraft", "_id")).to eq draft_id.to_s
    expect(DiscussionEntryDraft.find(draft_id).message).to eq "hello entry"
  end

  it "allows creating for an entry" do
    result = run_mutation(discussion_topic_id: @topic.id,
                          message: "edit in progress for entry",
                          discussion_entry_id: root.id)
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "createDiscussionEntryDraft", "errors")).to be_nil

    draft = @topic.discussion_entry_drafts.last
    expect(result.dig("data", "createDiscussionEntryDraft", "discussionEntryDraft", "_id")).to eq draft.id.to_s
    expect(draft.message).to eq "edit in progress for entry"
    expect(draft.discussion_entry_id).to eq root.id
  end

  it "sets root_entry_id" do
    result = run_mutation(discussion_topic_id: @topic.id, message: "threaded reply", parent_entry_id: parent.id)
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "createDiscussionEntryDraft", "errors")).to be_nil

    draft = @topic.discussion_entry_drafts.last
    expect(draft.root_entry_id).to eq root.id
  end

  it "updates existing root_entry draft on new parent_entry" do
    draft_id = DiscussionEntryDraft.upsert_draft(user: @teacher, topic: @topic, message: "hello", parent:).first
    result = run_mutation(discussion_topic_id: @topic.id, message: "threaded reply", parent_entry_id: sub.id)
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "createDiscussionEntryDraft", "errors")).to be_nil

    first_draft = DiscussionEntryDraft.find(draft_id)
    expect(first_draft.reload.parent_id).to eq sub.id
    expect(first_draft.root_entry_id).to eq parent.root_entry_id
    expect(first_draft.message).to eq "threaded reply"
  end

  context "errors" do
    it "if given a bad discussion topic id" do
      result = run_mutation(discussion_topic_id: @topic.id + 1337, message: "this should fail")
      expect(result.dig("data", "createDiscussionEntryDraft")).to be_nil
      expect(result.dig("errors", 0, "message")).to eq "not found"
    end

    it "if the user does not have permission to read" do
      user = user_model
      result = run_mutation({ discussion_topic_id: @topic.id, message: "this should fail" }, user)
      expect(result.dig("data", "createDiscussionEntryDraft")).to be_nil
      expect(result.dig("errors", 0, "message")).to eq "not found"
    end

    it "if given a bad attachment id" do
      result = run_mutation(discussion_topic_id: @topic.id, message: "this should fail", file_id: 1337)
      expect(result.dig("data", "createDiscussionEntryDraft")).to be_nil
      expect(result.dig("errors", 0, "message")).to eq "not found"
    end

    it "if the user does not own the attachment" do
      attachment = attachment_with_context(user_model)
      result = run_mutation(discussion_topic_id: @topic.id, message: "this should fail", file_id: attachment.id)
      expect(result.dig("data", "createDiscussionEntryDraft")).to be_nil
      expect(result.dig("errors", 0, "message")).to eq "not found"
    end
  end
end
