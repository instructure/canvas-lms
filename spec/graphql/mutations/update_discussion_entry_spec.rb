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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require_relative '../graphql_spec_helper'

RSpec.describe Mutations::UpdateDiscussionEntry do
  before(:once) do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
    discussion_topic_model({context: @course})
    @attachment = attachment_with_context(@student)
    @entry = @topic.discussion_entries.create!(message: 'Howdy', user: @student, attachment: @attachment)
  end

  def mutation_str(
    discussion_entry_id: nil,
    message: nil,
    remove_attachment: nil,
    file_id: nil
  )
    <<~GQL
      mutation {
        updateDiscussionEntry(input: {
          discussionEntryId: #{discussion_entry_id}
          #{"message: \"#{message}\"" unless message.nil?}
          #{"removeAttachment: #{remove_attachment}" unless remove_attachment.nil?}
          #{"fileId: #{file_id}" unless file_id.nil?}
        }) {
          discussionEntry {
            _id
            message
            attachment {
              _id
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
      mutation_str(opts),
      context: {
        current_user: current_user,
        request: ActionDispatch::TestRequest.create
      }
    )
    result.to_h.with_indifferent_access
  end

  it 'updates a discussion entry message' do
    result = run_mutation(discussion_entry_id: @entry.id, message: 'New message')
    expect(result.dig('errors')).to be nil
    expect(result.dig('data', 'updateDiscussionEntry', 'errors')).to be nil
    expect(result.dig('data', 'updateDiscussionEntry', 'discussionEntry', 'message')).to eq 'New message'
    expect(@entry.reload.message).to eq 'New message'
  end

  it 'removes a discussion entry attachment' do
    result = run_mutation(discussion_entry_id: @entry.id, remove_attachment: true)
    expect(result.dig('errors')).to be nil
    expect(result.dig('data', 'updateDiscussionEntry', 'errors')).to be nil
    expect(result.dig('data', 'updateDiscussionEntry', 'discussionEntry', 'attachment')).to be nil
    expect(@entry.reload.attachment).to be nil
  end

  it 'replaces a discussion entry attachment' do
    attachment = attachment_with_context(@student)
    attachment.update!(user: @student)
    result = run_mutation(discussion_entry_id: @entry.id, file_id: attachment.id)
    expect(result.dig('errors')).to be nil
    expect(result.dig('data', 'updateDiscussionEntry', 'errors')).to be nil
    expect(result.dig('data', 'updateDiscussionEntry', 'discussionEntry', 'attachment', '_id')).to eq attachment.id.to_s
    expect(@entry.reload.attachment_id).to eq attachment.id
  end

  context 'errors' do
    it 'if given a bad discussion entry id' do
      result = run_mutation(discussion_entry_id: @entry.id + 1337, message: 'should fail')
      expect(result.dig('data', 'updateDiscussionEntry')).to be nil
      expect(result.dig('errors', 0, 'message')).to eq 'not found'
    end

    it 'if the user does not have permission to read' do
      user = user_model
      result = run_mutation({discussion_entry_id: @entry.id, message: 'should fail'}, user)
      expect(result.dig('data', 'updateDiscussionEntry')).to be nil
      expect(result.dig('errors', 0, 'message')).to eq 'not found'
    end

    it 'if the user does not have permission to update' do
      entry = @topic.discussion_entries.create!(message: 'teacher message', user: @teacher)
      result = run_mutation({discussion_entry_id: entry.id, message: 'should fail'}, @student)
      expect(result.dig('data', 'updateDiscussionEntry', 'discussionEntry')).to be nil
      expect(result.dig('data', 'updateDiscussionEntry', 'errors', 0, 'message')).to eq 'Insufficient Permissions'
    end

    it 'if given a bad attachment id' do
      result = run_mutation(discussion_entry_id: @entry.id, file_id: @attachment.id + 1337)
      expect(result.dig('data', 'updateDiscussionEntry')).to be nil
      expect(result.dig('errors', 0, 'message')).to eq 'not found'
    end

    it 'if the user does not own the attachment' do
      attachment = attachment_with_context(@teacher)
      attachment.update!(user: @teacher)
      result = run_mutation(discussion_entry_id: @entry.id, file_id: attachment.id)
      expect(result.dig('data', 'updateDiscussionEntry')).to be nil
      expect(result.dig('errors', 0, 'message')).to eq 'not found'
    end
  end
end
