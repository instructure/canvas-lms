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

RSpec.describe Mutations::UpdateDiscussionReadState do
  before(:once) do
    course_with_teacher(active_all: true)
    topic_with_nested_replies
  end

  def mutation_str(
    id: nil,
    read: true
  )
    <<~GQL
      mutation {
        updateDiscussionReadState(input: {
          discussionTopicId: #{id}
          read: #{read}
        }) {
          discussionTopic {
            title
            discussionEntriesConnection {
              nodes {
                message
              }
            }
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
        domain_root_account: @course.account.root_account,
        request: ActionDispatch::TestRequest.create
      }
    )
    result.to_h.with_indifferent_access
  end

  it "marks all as unread" do
    @topic.change_all_read_state(:read, @teacher)
    result = run_mutation({ id: @topic.id, read: false })
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateDiscussionReadState", "discussionTopic", "title")).to eq @topic.title
    scope = @topic.discussion_entry_participants.where(user: @teacher)
                  .where.not(discussion_entries: { workflow_state: "deleted" })
    expect(scope.pluck(:workflow_state)).not_to include("read")
  end

  it "marks all as read" do
    expect(@topic.unread_count(@teacher)).to eq 5
    result = run_mutation({ id: @topic.id, read: true })
    expect(@topic.unread_count(@teacher)).to eq 0
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateDiscussionReadState", "discussionTopic", "title")).to eq @topic.title
    scope = @topic.discussion_entry_participants.where(user: @teacher)
                  .where.not(discussion_entries: { workflow_state: "deleted" })
    expect(scope.pluck(:workflow_state)).not_to include("unread")
  end
end
