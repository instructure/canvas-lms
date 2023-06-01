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

RSpec.describe Mutations::SubscribeToDiscussionTopic do
  before(:once) do
    course_with_teacher(active_all: true)
    discussion_topic_model({ context: @course })
  end

  def mutation_str(
    id: nil,
    subscribed: true
  )
    <<~GQL
      mutation {
        subscribeToDiscussionTopic(input: {
          discussionTopicId: #{id}
          subscribed: #{subscribed}
        }) {
          discussionTopic {
            subscribed
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

  it "subscribes to the discussion topic" do
    @topic.unsubscribe(@teacher)
    expect(@topic.subscribed?(@teacher)).to be false

    result = run_mutation({ id: @topic.id, subscribed: true })
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "subscribeToDiscussionTopic", "discussionTopic", "subscribed")).to be true
    @topic.reload
    expect(@topic.subscribed?(@teacher)).to be true
  end

  it "unsubscribes to the discussion topic" do
    @topic.subscribe(@teacher)
    expect(@topic.subscribed?(@teacher)).to be true

    result = run_mutation({ id: @topic.id, subscribed: false })
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "subscribeToDiscussionTopic", "discussionTopic", "subscribed")).to be false
    @topic.reload
    expect(@topic.subscribed?(@teacher)).to be false
  end
end
