# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

RSpec.describe Mutations::AddConversationMessage do
  before(:once) do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
  end

  def conversation(opts = {})
    num_other_users = opts[:num_other_users] || 1
    course = opts[:course] || @course
    user_data = num_other_users.times.map { {name: 'User'} }
    users = opts[:users] || create_users_in_course(course, user_data, account_associations: true, return_type: :record)
    @conversation = @user.initiate_conversation(users)
    @conversation.add_message(opts[:message] || 'test')
    @conversation.conversation.update_attribute(:context, course)
    @conversation
  end

  # rubocop:disable Metrics/ParameterLists
  def mutation_str(
    conversation_id: nil,
    body: nil,
    recipients: nil,
    included_messages: nil,
    attachment_ids: nil,
    media_comment_id: nil,
    media_comment_type: nil,
    user_note: nil
  )
    <<~GQL
      mutation {
        addConversationMessage(input: {
          conversationId: "#{conversation_id}"
          body: "#{body}"
          recipients: #{recipients}
          #{"includedMessages: #{included_messages}" if included_messages}
          #{"attachmentIds: #{attachment_ids}" if attachment_ids}
          #{"mediaCommentId: \"#{media_comment_id}\"" if media_comment_id}
          #{"mediaCommentType: \"#{media_comment_type}\"" if media_comment_type}
          #{"userNote: #{user_note}" unless user_note.nil?}
        }) {
          conversationMessage {
            _id
            attachmentsConnection {
              nodes {
                displayName
              }
            }
            author {
              name
            }
            body
            conversationId
            mediaComment {
              _id
              title
            }
          }
          errors {
            attribute
            message
          }
        }
      }
    GQL
  end
  # rubocop:enable Metrics/ParameterLists

  def run_mutation(opts = {}, current_user = @student)
    result = CanvasSchema.execute(
      mutation_str(opts),
      context: {
        current_user: current_user,
        domain_root_account: @course.account.root_account,
        request: ActionDispatch::TestRequest.create
      }
    )
    result.to_h.with_indifferent_access
  end

  it 'should add a message' do
    conversation
    result = run_mutation(conversation_id: @conversation.conversation_id, body: 'This is a neat message', recipients: [@teacher.id.to_s])

    expect(result.dig('errors')).to be nil
    expect(result.dig('data', 'addConversationMessage', 'errors')).to be nil
    expect(
      result.dig('data', 'addConversationMessage', 'conversationMessage', 'body')
    ).to eq 'This is a neat message'
    cm = ConversationMessage.find(result.dig('data', 'addConversationMessage', 'conversationMessage', '_id'))
    expect(cm).to_not be nil
    expect(cm.conversation_id).to eq @conversation.conversation_id
  end

  it 'should require permissions' do
    conversation
    @course.account.role_overrides.create!(permission: :send_messages, role: student_role, enabled: false)

    result = run_mutation(conversation_id: @conversation.conversation_id, body: 'need some perms yo', recipients: [@teacher.id.to_s])
    expect(result.dig('errors')).to be nil
    expect(result.dig('data', 'addConversationMessage', 'conversationMessage')).to be nil
    expect(
      result.dig('data', 'addConversationMessage', 'errors', 0, 'message')
    ).to eq 'Unauthorized, unable to add messages to conversation'
  end

  it 'should queue a job if needed' do
    # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(ConversationParticipant).to receive(:should_process_immediately?).and_return(false)
    # rubocop:enable RSpec/AnyInstance
    conversation
    result = run_mutation(conversation_id: @conversation.conversation_id, body: 'This should be delayed', recipients: [@teacher.id.to_s])

    expect(result.dig('errors')).to be nil
    # a nil result with no errors implies that the message was delayed and will be processed later
    expect(result.dig('data', 'addConversationMessage', 'conversationMessage')).to be nil
    expect(@conversation.reload.messages.count(:all)).to eq 1
    run_jobs
    expect(@conversation.reload.messages.count(:all)).to eq 2
  end

  it 'should generate a user note when requested' do
    Account.default.update_attribute(:enable_user_notes, true)
    conversation(users: [@teacher])

    result = run_mutation({conversation_id: @conversation.conversation_id, body: 'Have a note', recipients: [@student.id.to_s]}, @teacher)
    expect(result.dig('errors')).to be nil
    cm = ConversationMessage.find(result.dig('data', 'addConversationMessage', 'conversationMessage', '_id'))
    student = cm.recipients.first
    expect(student.user_notes.size).to eq 0

    result = run_mutation({conversation_id: @conversation.conversation_id, body: 'Have a note', recipients: [@student.id.to_s], user_note: true}, @teacher)
    expect(result.dig('errors')).to be nil
    cm = ConversationMessage.find(result.dig('data', 'addConversationMessage', 'conversationMessage', '_id'))
    student = cm.recipients.first
    expect(student.user_notes.size).to eq 1
  end

  it 'should not allow new messages in concluded courses for students' do
    conversation
    @course.update!(workflow_state: 'completed')

    result = run_mutation(conversation_id: @conversation.conversation_id, body: 'uh uh uh', recipients: [@teacher.id.to_s])
    expect(result.dig('errors')).to be nil
    expect(result.dig('data', 'addConversationMessage', 'conversationMessage')).to be nil
    expect(
      result.dig('data', 'addConversationMessage', 'errors', 0, 'message')
    ).to eq 'Course concluded, unable to send messages'
  end

  it 'should allow new messages in concluded courses for teachers' do
    conversation(users: [@teacher])
    @course.update!(workflow_state: 'completed')

    result = run_mutation({conversation_id: @conversation.conversation_id, body: 'I have the power', recipients: [@student.id.to_s]}, @teacher)
    expect(result.dig('errors')).to be nil
    expect(
      result.dig('data', 'addConversationMessage', 'conversationMessage', 'body')
    ).to eq 'I have the power'
  end
end
