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

RSpec.describe Mutations::CreateConversation do
  before(:once) do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
  end

  def conversation(opts = {})
    num_other_users = opts[:num_other_users] || 1
    course = opts[:course] || @course
    user_data = num_other_users.times.map { {name: 'User'} }
    users = create_users_in_course(course, user_data, account_associations: true, return_type: :record)
    @conversation = @user.initiate_conversation(users)
    @conversation.add_message(opts[:message] || 'test')
    @conversation.conversation.update_attribute(:context, course)
    @conversation
  end

  def mutation_str(
    recipients: nil,
    subject: nil,
    body: nil,
    bulk_message: nil,
    force_new: nil,
    group_conversation: nil,
    attachment_ids: nil,
    media_comment_id: nil,
    media_comment_type: nil,
    context_code: nil,
    conversation_id: nil,
    user_note: nil,
    tags: nil
  )
    <<~GQL
      mutation {
        createConversation(input: {
          recipients: #{recipients}
          #{"subject: \"#{subject}\"" if subject}
          body: "#{body}"
          #{"bulkMessage: #{bulk_message}" unless bulk_message.nil?}
          #{"forceNew: #{force_new}" unless force_new.nil?}
          #{"groupConversation: #{group_conversation}" unless group_conversation.nil?}
          #{"attachmentIds: #{attachment_ids}" if attachment_ids}
          #{"mediaCommentId: \"#{media_comment_id}\"" if media_comment_id}
          #{"mediaCommentType: \"#{media_comment_type}\"" if media_comment_type}
          #{"contextCode: \"#{context_code}\"" if context_code}
          #{"conversationId: \"#{conversation_id}\"" if conversation_id}
          #{"userNote: #{user_note}" unless user_note.nil?}
          #{"tags: #{tags}" if tags}
        }) {
          conversations {
            conversation {
              _id
              contextId
              contextType
              subject
              conversationMessagesConnection {
                nodes {
                  _id
                  body
                  conversationId
                  author {
                    _id
                    name
                  }
                  attachmentsConnection {
                    nodes {
                      _id
                      displayName
                    }
                  }
                }
              }
              conversationParticipantsConnection {
                nodes {
                  _id
                  user {
                    _id
                    name
                  }
                }
              }
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
        domain_root_account: @course.account.root_account,
        request: ActionDispatch::TestRequest.create
      }
    )
    result.to_h.with_indifferent_access
  end

  it 'creates a conversation' do
    new_user = User.create
    enrollment = @course.enroll_student(new_user)
    enrollment.workflow_state = 'active'
    enrollment.save
    result = run_mutation(recipients: [new_user.id.to_s], body: 'yo')

    expect(result.dig('errors')).to be nil
    expect(
      result.dig('data', 'createConversation', 'conversations', 0, 'conversation', 'conversationMessagesConnection', 'nodes', 0, 'body')
    ).to eq 'yo'
  end

  it 'should not allow creating conversations in concluded courses for students' do
    @course.update!(workflow_state: 'completed')

    result = run_mutation(recipients: [@teacher.id.to_s], body: 'yo', context_code: @course.asset_string)

    expect(result.dig('data', 'createConversation', 'conversations')).to be nil
    expect(
      result.dig('data', 'createConversation', 'errors', 0, 'message')
    ).to eq "Unable to send messages to users in #{@course.name}"
  end

  it 'should allow creating conversations in concluded courses for teachers' do
    teacher2 = teacher_in_course(active_all: true).user
    @course.update!(workflow_state: 'claimed')

    result = run_mutation({recipients: [teacher2.id.to_s], body: 'yo', context_code: @course.asset_string}, @teacher)
    expect(
      result.dig('data', 'createConversation', 'conversations', 0, 'conversation', 'conversationMessagesConnection', 'nodes', 0, 'body')
    ).to eq 'yo'
  end

  it 'requires permissions for sending to other students' do
    new_user = User.create
    enrollment = @course.enroll_student(new_user)
    enrollment.workflow_state = 'active'
    enrollment.save
    @course.account.role_overrides.create!(permission: :send_messages, role: student_role, enabled: false)

    result = run_mutation(recipients: [new_user.id.to_s], body: 'yo', context_code: @course.asset_string)
    expect(
      result.dig('data', 'createConversation', 'errors', 0, 'message')
    ).to eq 'Invalid recipients'
  end

  it 'should allow sending to instructors even if permissions are disabled' do
    @course.account.role_overrides.create!(permission: :send_messages, role: student_role, enabled: false)

    result = run_mutation(recipients: [@teacher.id.to_s], body: 'yo', context_code: @course.asset_string)
    expect(
      result.dig('data', 'createConversation', 'conversations', 0, 'conversation', 'conversationMessagesConnection', 'nodes', 0, 'body')
    ).to eq 'yo'
  end

  it 'allows observers to message linked students' do
    observer = user_with_pseudonym
    add_linked_observer(@student, observer, root_account: @course.root_account)

    result = run_mutation({recipients: [@student.id.to_s], body: 'Hello there', context_code: @course.asset_string}, observer)
    expect(
      result.dig('data', 'createConversation', 'conversations', 0, 'conversation', 'conversationMessagesConnection', 'nodes', 0, 'body')
    ).to eq 'Hello there'
  end

  it 'infers context tags' do
    course_with_teacher_logged_in(active_all: true)
    @course1 = @course
    @course2 = course_factory(active_all: true)
    @course2.enroll_teacher(@user).accept
    @course3 = course_factory(active_all: true)
    @course3.enroll_student(@user)
    @group1 = @course1.groups.create!
    @group2 = @course1.groups.create!
    @group3 = @course3.groups.create!
    @group1.users << @user
    @group2.users << @user
    @group3.users << @user

    new_user1 = User.create
    enrollment1 = @course1.enroll_student(new_user1)
    enrollment1.workflow_state = 'active'
    enrollment1.save
    @group1.users << new_user1
    @group2.users << new_user1

    new_user2 = User.create
    enrollment2 = @course1.enroll_student(new_user2)
    enrollment2.workflow_state = 'active'
    enrollment2.save
    @group1.users << new_user2
    @group2.users << new_user2

    new_user3 = User.create
    enrollment3 = @course2.enroll_student(new_user3)
    enrollment3.workflow_state = 'active'
    enrollment3.save

    result = run_mutation(
      {
        recipients: [
          @course2.asset_string + '_students',
          @group1.asset_string
        ],
        body: 'yo',
        group_conversation: true,
        context_code: @group3.asset_string
      },
      @user
    )
    conversation_id = result.dig('data', 'createConversation', 'conversations', 0, 'conversation', '_id')
    expect(conversation_id).not_to be_nil
    c = Conversation.find(conversation_id)
    expect(c.tags.sort).to eql [@course1.asset_string, @course2.asset_string, @course3.asset_string, @group1.asset_string, @group3.asset_string].sort
  end

  context 'group conversations' do
    before(:once) do
      @old_count = Conversation.count

      @new_user1 = User.create
      @course.enroll_student(@new_user1).accept!

      @new_user2 = User.create
      @course.enroll_student(@new_user2).accept!

      @account_id = @course.account_id
    end

    it 'creates a conversation shared by all recipients' do
      result = run_mutation(recipients: [@new_user1.id.to_s, @new_user2.id.to_s], body: 'yo', group_conversation: true)

      expect(
        result.dig('data', 'createConversation', 'conversations', 0, 'conversation', 'conversationParticipantsConnection', 'nodes').
          pluck('user').
          pluck('_id').sort
      ).to eql [@student.id.to_s, @new_user1.id.to_s, @new_user2.id.to_s].sort
      expect(Conversation.count).to eql(@old_count + 1)
    end

    it 'creates one conversation per recipient' do
      result = run_mutation(recipients: [@new_user1.id.to_s, @new_user2.id.to_s], body: 'yo', group_conversation: false)

      expect(
        result.dig('data', 'createConversation', 'conversations').count
      ).to eql 2
      expect(Conversation.count).to eql(@old_count + 2)
    end

    it 'sets the root account id to the participants for group conversations' do
      result = run_mutation(recipients: [@new_user1.id.to_s, @new_user2.id.to_s], body: 'yo', group_conversation: true)

      participant_ids = result.dig('data', 'createConversation', 'conversations', 0, 'conversation', 'conversationParticipantsConnection', 'nodes').
        pluck('_id')
      participant_ids.each do |participant_id|
        cp = ConversationParticipant.find(participant_id)
        expect(cp.root_account_ids).to eq [@account_id]
      end
    end

    it 'does not allow sending messages to other users in a group if the permission is disabled' do
      @course.account.role_overrides.create!(permission: :send_messages, role: student_role, enabled: false)
      result = run_mutation(recipients: [@new_user2.id.to_s], body: 'ooo eee', group_conversation: true, context_code: @course.asset_string)

      expect(result.dig('data', 'createConversation', 'conversations')).to be nil
      expect(
        result.dig('data', 'createConversation', 'errors', 0, 'message')
      ).to eql 'Invalid recipients'
    end
  end

  context 'user_notes' do
    before(:each) do
      Account.default.update_attribute(:enable_user_notes, true)
      @students = create_users_in_course(@course, 2, account_associations: true, return_type: :record)
    end

    it 'creates user notes' do
      run_mutation({recipients: @students.map(&:id).map(&:to_s), body: 'yo', subject: 'greetings', user_note: true}, @teacher)
      @students.each{|x| expect(x.user_notes.size).to be(1)}
    end

    it 'includes the domain root account in the user note' do
      run_mutation({recipients: @students.map(&:id).map(&:to_s), body: 'hi there', subject: 'hi there', user_note: true}, @teacher)
      note = UserNote.last
      expect(note.root_account_id).to eql Account.default.id
    end
  end

  describe 'for recipients the sender has no relationship with' do
    it 'should fail for normal users' do
      result = run_mutation(recipients: [User.create.id.to_s], body: 'foo')

      expect(result.dig('data', 'createConversation', 'conversations')).to be nil
      expect(
        result.dig('data', 'createConversation', 'errors', 0, 'message')
      ).to eql 'Invalid recipients'
    end

    it 'should succeed for siteadmins with send_messages grants' do
      result = run_mutation({recipients: [User.create.id.to_s], body: 'foo'}, site_admin_user)

      expect(
        result.dig('data', 'createConversation', 'conversations', 0, 'conversation', 'conversationMessagesConnection', 'nodes', 0, 'body')
      ).to eql 'foo'
    end
  end
end
