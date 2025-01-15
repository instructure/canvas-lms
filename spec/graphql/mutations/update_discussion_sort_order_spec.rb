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

RSpec.describe Mutations::UpdateDiscussionSortOrder do
  let(:discussion_type) { GraphQLTypeTester.new(@topic, current_user: @student) }

  before(:once) do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
    discussion_topic_model({ context: @course })
    @root_entry = @topic.discussion_entries.create!(message: "I am root", user: @student)
    @first = @topic.discussion_entries.create!(message: "First !", user: @student, parent_id: @root_entry.id)
    @second = @topic.discussion_entries.create!(message: "Second !", user: @student, parent_id: @root_entry.id)
    @third = @topic.discussion_entries.create!(message: "Third", user: @student, parent_id: @root_entry.id)
  end

  def mutation_str(
    discussion_topic_id: nil,
    sort: nil
  )
    <<~GQL
      mutation {
        updateDiscussionSortOrder(input: {
          discussionTopicId: "#{discussion_topic_id}"
          sortOrder: #{sort}
        }) {
          discussionTopic {
            _id
            participant {
              sortOrder
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

  it "updates a discussion topic participant's sort order" do
    # default sort order is desc
    expect(discussion_type.resolve(:sortOrder)).to eq("desc")

    result = run_mutation(discussion_topic_id: @topic.id, sort: :asc)
    expect(result[:data][:updateDiscussionSortOrder][:discussionTopic][:participant][:sortOrder]).to eq("asc")

    result = run_mutation(discussion_topic_id: @topic.id, sort: :desc)
    expect(result[:data][:updateDiscussionSortOrder][:discussionTopic][:participant][:sortOrder]).to eq("desc")
  end

  it "does not update when discussion topic default sort order locked is true" do
    Account.site_admin.enable_feature!(:discussion_default_sort)
    expect(discussion_type.resolve(:sortOrder)).to eq("desc")
    @topic.update!(sort_order_locked: true)
    result = run_mutation(discussion_topic_id: @topic.id, sort: :asc)
    # it did not update
    expect(result[:data][:updateDiscussionSortOrder][:discussionTopic][:participant][:sortOrder]).to eq("desc")
  end

  it "does update when discussion_default_sort flag is off" do
    Account.site_admin.disable_feature!(:discussion_default_sort)
    expect(discussion_type.resolve(:sortOrder)).to eq("desc")
    result = run_mutation(discussion_topic_id: @topic.id, sort: :asc)
    # it did update
    expect(result[:data][:updateDiscussionSortOrder][:discussionTopic][:participant][:sortOrder]).to eq("asc")
  end
end
