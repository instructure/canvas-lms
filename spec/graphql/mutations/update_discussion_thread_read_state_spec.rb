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
    @root_entry = @topic.discussion_entries.create!(message: "I am root", user: @student)
    @parent_entry = @topic.discussion_entries.create!(message: "I am parent", user: @student, parent_id: @root_entry.id)
    @child_entry = @topic.discussion_entries.create!(message: "I am child", user: @student, parent_id: @parent_entry.id)
    @topic.update!(discussion_type: "threaded")
  end

  def mutation_str(
    discussion_entry_id: nil,
    read: nil
  )
    <<~GQL
      mutation {
        updateDiscussionThreadReadState(input: {
          discussionEntryId: #{discussion_entry_id}
          #{"read: #{read}" unless read.nil?}
        }) {
          discussionEntry {
            _id
            entryParticipant {#{" "}
              read
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

  it "updates a discussion entry and its childred's read state" do
    expect(@root_entry.discussion_topic.unread_count(@student)).to eq 0
    result = run_mutation(discussion_entry_id: @root_entry.id, read: false)
    expect(@root_entry.discussion_topic.unread_count(@student)).to eq 3
    expect(result["errors"]).to be_nil
    expect(@root_entry.reload.read?(@student)).to be false
    expect(@root_entry.find_existing_participant(@student).forced_read_state).to be true
    expect(@parent_entry.reload.read?(@student)).to be false
    expect(@parent_entry.find_existing_participant(@student).forced_read_state).to be true
    expect(@child_entry.reload.read?(@student)).to be false
    expect(@child_entry.find_existing_participant(@student).forced_read_state).to be true
    result = run_mutation(discussion_entry_id: @root_entry.id, read: true)
    expect(@root_entry.discussion_topic.unread_count(@student)).to eq 0
    expect(result["errors"]).to be_nil
    expect(@root_entry.reload.read?(@student)).to be true
    expect(@parent_entry.reload.read?(@student)).to be true
    expect(@child_entry.reload.read?(@student)).to be true
  end
end
