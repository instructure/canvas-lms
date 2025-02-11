# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

RSpec.describe Mutations::UpdateDiscussionExpanded do
  let(:discussion_type) { GraphQLTypeTester.new(@topic, current_user: @student) }

  before(:once) do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
    discussion_topic_model({ context: @course })
    @root_entry = @topic.discussion_entries.create!(message: "I am root", user: @student)
  end

  def mutation_str(
    discussion_topic_id: nil,
    expanded: nil
  )
    <<~GQL
      mutation {
        updateDiscussionExpanded(input: {
          discussionTopicId: "#{discussion_topic_id}"
          expanded: #{expanded}
        }) {
          discussionTopic {
            _id
            id
            participant {
              expanded
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

  it "updates a discussion topic participant's expanded" do
    # false by default
    expect(discussion_type.resolve(:expanded)).to be(false)

    result = run_mutation(discussion_topic_id: @topic.id, expanded: true)
    expect(result[:data][:updateDiscussionExpanded][:discussionTopic][:participant][:expanded]).to be true

    result = run_mutation(discussion_topic_id: @topic.id, expanded: false)
    expect(result[:data][:updateDiscussionExpanded][:discussionTopic][:participant][:expanded]).to be false
  end

  it "does not update when discussion topic default expand locked is true" do
    Account.site_admin.enable_feature!(:discussion_default_expand)
    expect(discussion_type.resolve(:expanded)).to be(false)
    @topic.update!(expanded: true)
    @topic.update!(expanded_locked: true)
    result = run_mutation(discussion_topic_id: @topic.id, expanded: false)
    # it did not update
    expect(result[:data][:updateDiscussionExpanded][:discussionTopic][:participant][:expanded]).to be true
  end

  it "does update when discussion_default_expand flag is off" do
    Account.site_admin.disable_feature!(:discussion_default_expand)
    expect(discussion_type.resolve(:expanded)).to be(false)
    result = run_mutation(discussion_topic_id: @topic.id, expanded: true)
    # it did update
    expect(result[:data][:updateDiscussionExpanded][:discussionTopic][:participant][:expanded]).to be true
  end
end
