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

require "spec_helper"
require_relative "../graphql_spec_helper"

describe Mutations::DeleteDiscussionEntries do
  before(:once) do
    course_with_teacher(:active_all => true)
    course_with_student(:user => sender, :course => @course)
  end

  let(:sender) {user_model}
  let(:topic) { @course.discussion_topics.create! }
  let(:discussion_entry) {topic.discussion_entries.create!(user: sender)}

  def execute_with_input(delete_input, user_executing: sender)
    mutation_command = <<~GQL
      mutation {
        deleteDiscussionEntries(input: {
          #{delete_input}
        }) {
          discussionEntryIds
          errors {
            attribute
            message
          }
        }
      }
    GQL
    context = {current_user: user_executing, request: ActionDispatch::TestRequest.create}
    CanvasSchema.execute(mutation_command, context: context)
  end

  it "destroys the discussion entry and returns ids" do
    query = <<~QUERY
      ids: [#{discussion_entry.id}]
    QUERY
    expect(DiscussionEntry.where("user_id = #{sender.id} and deleted_at is null").length).to eq 1
    result = execute_with_input(query)
    expect(result.dig('errors')).to be_nil
    expect(result.dig('data', 'discussionEntryIds', 'errors')).to be_nil
    expect(result.dig('data', 'deleteDiscussionEntries', 'discussionEntryIds')).to match_array %W(#{discussion_entry.id})
    expect(DiscussionEntry.where("user_id = #{sender.id} and deleted_at is null").count).to eq 0
  end

  context "errors" do
    def expect_error(result, message)
      errors = result.dig('errors') || result.dig('data', 'deleteDiscussionEntries', 'errors')
      expect(errors).not_to be_nil
      expect(errors[0]['message']).to match(/#{message}/)
    end

    it "returns nil if the discussion entry doesn't exist" do
      query = <<~QUERY
        ids: [#{DiscussionEntry.maximum(:id)&.next || 0}]
      QUERY
      result = execute_with_input(query)
      expect_error(result, 'Unable to find Discussion Entry')
    end

    context "user does not have read permissions" do
      it "fails if the requesting user is not the discussion entry user" do
        query = <<~QUERY
          ids: [#{discussion_entry.id}]
        QUERY
        result = execute_with_input(query, user_executing: user_model)
        expect_error(result, 'Unable to find Discussion Entry')
      end
    end
    
    context "user can read the discussion entry" do
      it "fails with Insufficient permissions if the requesting user is not the discussion entry user" do
        query = <<~QUERY
          ids: [#{discussion_entry.id}]
        QUERY
        result = execute_with_input(query, user_executing: @student)
        expect_error(result, 'Insufficient permissions')
      end
    end
  end

  context "batching" do
    context "all ids are valid" do
      let(:discussion_entry_2) {topic.discussion_entries.create!(user: sender)}

      it "removes discussion entry from each view" do
        query = <<~QUERY
          ids: [#{discussion_entry.id}, #{discussion_entry_2.id}]
        QUERY
        
        expect(DiscussionEntry.where("user_id = #{sender.id} and deleted_at is null and id = #{discussion_entry.id}").length).to eq 1
        expect(DiscussionEntry.where("user_id = #{sender.id} and deleted_at is null and id = #{discussion_entry_2.id}").length).to eq 1

        result = execute_with_input(query)
        expect(result.dig('errors')).to be_nil
        expect(result.dig('data', 'deleteDiscussionEntries', 'errors')).to be_nil
        expect(result.dig('data', 'deleteDiscussionEntries', 'discussionEntryIds')).to match_array %W(#{discussion_entry.id} #{discussion_entry_2.id})

        expect(DiscussionEntry.where("user_id = #{sender.id} and deleted_at is null and id = #{discussion_entry.id}").length).to eq 0
        expect(DiscussionEntry.where("user_id = #{sender.id} and deleted_at is null and id = #{discussion_entry_2.id}").length).to eq 0

      end
    end

    context "some ids are invalid" do
      let(:another_discussion_entry) {topic.discussion_entries.create!(user: user_model)}
      let(:invalid_id) {DiscussionEntry.maximum(:id)&.next || 0}

      def expect_error(result, id, message)
        errors = result.dig('errors') || result.dig('data', 'deleteDiscussionEntries', 'errors')
        expect(errors).not_to be_nil
        error = errors.find {|i| i["attribute"] == id.to_s}
        expect(error['message']).to match(/#{message}/)
      end

      it "handles error entries and won't delete valid entry" do
        query = <<~QUERY
          ids: [#{discussion_entry.id}, #{another_discussion_entry.id}, #{invalid_id}]
        QUERY

        expect(DiscussionEntry.where("user_id = #{sender.id} and deleted_at is null and id = #{discussion_entry.id}").length).to eq 1

        result = execute_with_input(query)
        expect_error(result, another_discussion_entry.id, 'Unable to find Discussion Entry')
        expect_error(result, invalid_id, 'Unable to find Discussion Entry')
        expect(result.dig('data', 'deleteDiscussionEntries', 'discussionEntryIds')).to match_array %W(#{discussion_entry.id})
        expect(DiscussionEntry.where("user_id = #{sender.id} and deleted_at is null and id = #{discussion_entry.id}").length).to eq 0
      end
    end
  end

end