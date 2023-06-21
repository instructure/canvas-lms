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

describe Mutations::DeleteDiscussionEntry do
  before(:once) do
    course_with_teacher(active_all: true)
    course_with_student(course: @course)
    @topic = @course.discussion_topics.create!
    @discussion_entry = @topic.discussion_entries.create!(user: @teacher)
  end

  def mutation_str(id: nil)
    <<~GQL
      mutation {
        deleteDiscussionEntry(input: {id: #{id}}) {
          discussionEntry {
            _id
            deleted
            editor {
              _id
              name
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

  it "marks a discussion entry as deleted" do
    expect(@discussion_entry.workflow_state).to eq "active"
    result = run_mutation(id: @discussion_entry.id)
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "deleteDiscussionEntry", "errors")).to be_nil
    expect(result.dig("data", "deleteDiscussionEntry", "discussionEntry", "_id")).to eq @discussion_entry.id.to_s
    expect(result.dig("data", "deleteDiscussionEntry", "discussionEntry", "deleted")).to be true
    expect(@discussion_entry.reload.workflow_state).to eq "deleted"
  end

  it "sets the editor when deleting" do
    expect(@discussion_entry.editor_id).to be_nil
    result = run_mutation(id: @discussion_entry.id)
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "deleteDiscussionEntry", "errors")).to be_nil
    expect(result.dig("data", "deleteDiscussionEntry", "discussionEntry", "editor", "_id")).to eq @teacher.id.to_s
    expect(@discussion_entry.reload.editor_id).to eq @teacher.id
  end

  context "errors" do
    it "if the record does not exist" do
      result = run_mutation(id: @discussion_entry.id + 1337)
      expect(result.dig("errors", 0, "message")).to eq "not found"
    end

    it "if the user does not have read access to the discussion entry" do
      user = user_model
      result = run_mutation({ id: @discussion_entry.id }, user)
      expect(result.dig("errors", 0, "message")).to eq "not found"
    end

    it "if the user does not have delete permissions" do
      result = run_mutation({ id: @discussion_entry.id }, @student)
      expect(result["errors"]).to be_nil
      expect(result.dig("data", "deleteDiscussionEntry", "errors", 0, "message")).to eq "Insufficient permissions"
    end
  end
end
