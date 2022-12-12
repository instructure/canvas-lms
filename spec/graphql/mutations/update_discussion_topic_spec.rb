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

RSpec.describe Mutations::UpdateDiscussionTopic do
  before(:once) do
    course_with_teacher(active_all: true)
    discussion_topic_model({ context: @course })
  end

  def mutation_str(
    id: nil,
    published: nil,
    locked: nil
  )
    <<~GQL
      mutation {
        updateDiscussionTopic(input: {
          discussionTopicId: #{id}
          #{"published: #{published}" unless published.nil?}
          #{"locked: #{locked}" unless locked.nil?}
        }) {
          discussionTopic {
            published
            locked
          }
        }
      }
    GQL
  end

  def run_mutation(opts = {}, current_user = @teacher)
    result = CanvasSchema.execute(
      mutation_str(**opts),
      context: {
        current_user: current_user,
        domain_root_account: @course.account.root_account,
        request: ActionDispatch::TestRequest.create
      }
    )
    result.to_h.with_indifferent_access
  end

  it "publishes the discussion topic" do
    @topic.unpublish!
    expect(@topic.published?).to be false

    result = run_mutation({ id: @topic.id, published: true })
    expect(result["errors"]).to be nil
    expect(result.dig("data", "updateDiscussionTopic", "discussionTopic", "published")).to be true
    @topic.reload
    expect(@topic.published?).to be true
  end

  it "unpublishes the discussion topic" do
    @topic.publish!
    expect(@topic.published?).to be true

    result = run_mutation({ id: @topic.id, published: false })
    expect(result["errors"]).to be nil
    expect(result.dig("data", "updateDiscussionTopic", "discussionTopic", "published")).to be false
    @topic.reload
    expect(@topic.published?).to be false
  end

  it "locks the discussion topic" do
    expect(@topic.locked).to be false

    result = run_mutation(id: @topic.id, locked: true)
    expect(result["errors"]).to be nil
    expect(result.dig("data", "updateDiscussionTopic", "discussionTopic", "locked")).to be true
    expect(@topic.reload.locked).to be true
  end

  it "unlocks the discussion topic" do
    @topic.lock!
    expect(@topic.locked).to be true

    result = run_mutation(id: @topic.id, locked: false)
    expect(result["errors"]).to be nil
    expect(result.dig("data", "updateDiscussionTopic", "discussionTopic", "locked")).to be false
    expect(@topic.reload.locked).to be false
  end
end
