#
# Copyright (C) 2011 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ConversationsController do
  def conversation(num_other_users = 1)
    user_ids = num_other_users.times.map{
      u = User.create
      enrollment = @course.enroll_student(u)
      enrollment.workflow_state = 'active'
      enrollment.save
      u.id
    }
    @conversation = @user.initiate_conversation(user_ids)
    @conversation.add_message('test')
    @conversation
  end

  describe "GET 'index'" do
    it "should require login" do
      course_with_student(:active_all => true)
      get 'index'
      assert_require_login
    end

    it "should assign variables" do
      course_with_student_logged_in(:active_all => true)
      conversation

      get 'index'
      response.should be_success
      assigns[:conversations].should == @user.conversations
    end
  end

  describe "GET 'show'" do
    it "should assign variables" do
      course_with_student_logged_in(:active_all => true)
      conversation

      get 'show', :id => @conversation.id
      response.should be_success
      assigns[:conversation].should == @conversation
    end
  end

  describe "POST 'update'" do
    it "should update the conversation" do
      course_with_student_logged_in(:active_all => true)
      conversation.mark_as_unread

      post 'update', :id => @conversation.id, :conversation => {:subscribed => "0"}
      response.should be_success
      @conversation.reload.subscribed?.should be_false
    end
  end

  describe "POST 'workflow_event'" do
    it "should trigger the workflow event" do
      course_with_student_logged_in(:active_all => true)
      conversation

      post 'workflow_event', :conversation_id => @conversation.id, :event => "mark_as_unread"
      response.should be_success
      @conversation.unread?.should be_true
    end
  end

  describe "POST 'add_message'" do
    it "should add a message" do
      course_with_student_logged_in(:active_all => true)
      conversation

      post 'add_message', :conversation_id => @conversation.id, :body => "hello world"
      response.should be_success
      @conversation.messages.size.should == 2
    end
  end

  describe "POST 'add_recipients'" do
    it "should add recipients" do
      course_with_student_logged_in(:active_all => true)
      conversation(2)

      new_user = User.create
      enrollment = @course.enroll_student(new_user)
      enrollment.workflow_state = 'active'
      enrollment.save
      post 'add_recipients', :conversation_id => @conversation.id, :users => [new_user.id]
      response.should be_success
      @conversation.participants.size.should == 4
    end
  end

  describe "POST 'remove_messages'" do
    it "should remove messages" do
      course_with_student_logged_in(:active_all => true)
      message = conversation.add_message('another')

      post 'remove_messages', :conversation_id => @conversation.id, :remove => [message.id]
      response.should be_success
      @conversation.messages.size.should == 1
    end
  end

  describe "DELETE 'destroy'" do
    it "should delete conversations" do
      course_with_student_logged_in(:active_all => true)
      conversation

      delete 'destroy', :id => @conversation.id
      response.should be_success
      @user.conversations.should be_blank # the conversation_participant is no longer there
      @conversation.conversation.should_not be_nil # though the conversation is
    end
  end

  describe "GET 'find_recipients'" do
    it "should assign variables" do
      course_with_student_logged_in(:active_all => true)
      other = User.create(:name => 'testuser')
      enrollment = @course.enroll_student(other)
      enrollment.workflow_state = 'active'
      enrollment.save

      get 'find_recipients', :search => other.name
      response.should be_success
      response.body.should include(other.name)
    end
  end
end