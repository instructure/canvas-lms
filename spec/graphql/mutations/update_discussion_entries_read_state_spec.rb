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

RSpec.describe Mutations::UpdateDiscussionEntriesReadState do
  before(:once) do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
    discussion_topic_model({ context: @course })
    @entries = []
    10.times do |i|
      @entries.push(@topic.discussion_entries.create!(message: "Howdy #{i}", user: @student))
    end
  end

  def mutation_str(ids: nil, read: nil)
    <<~GQL
      mutation {
        updateDiscussionEntriesReadState(input: {
          discussionEntryIds: #{ids}
          read: #{read}
        }) {
          discussionEntries {
            entryParticipant {
              read
            }
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

  it "updates the read state for the given entries" do
    expect(@topic.unread_count(@student)).to eq 0
    @entries.each do |entry|
      expect(entry.read?(@student)).to be true
    end

    result = run_mutation({ ids: @entries.map(&:id), read: false })
    expect(@topic.unread_count(@student)).to eq @entries.count
    expect(result["errors"]).to be_nil
    updated_entries = result.dig("data", "updateDiscussionEntriesReadState", "discussionEntries")

    updated_entries.each do |entry|
      expect(entry.dig("entryParticipant", "read")).to be false
    end

    @entries.each do |entry|
      expect(entry.reload.read?(@student)).to be false
    end
  end
end
