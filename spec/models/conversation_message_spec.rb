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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe ConversationMessage do
  context "notifications" do
    before(:each) do
      Notification.create(:name => "Conversation Message", :category => "TestImmediately")
      Notification.create(:name => "Added To Conversation", :category => "TestImmediately")

      course_with_teacher(:active_all => true)
      @students = []
      3.times{ @students << student_in_course(:active_all => true).user }
      @first_student = @students.first
      @initial_students = @students.first(2)
      @last_student = @students.last

      [@teacher, *@students].each do |user|
        channel = user.communication_channels.create(:path => "test_channel_email_#{user.id}", :path_type => "email")
        channel.confirm
      end

      @conversation = @teacher.initiate_conversation(@initial_students.map(&:id))
      add_message # need initial message for add_participants to not barf
    end

    def add_message
      @conversation.add_message("message")
    end

    def add_last_student
      @conversation.add_participants([@last_student.id])
    end

    it "should create appropriate notifications on new message" do
      message = add_message
      message.messages_sent.should be_include("Conversation Message")
      message.messages_sent.should_not be_include("Added To Conversation")
    end

    it "should create appropriate notifications on added participants" do
      event = add_last_student
      event.messages_sent.should_not be_include("Conversation Message")
      event.messages_sent.should be_include("Added To Conversation")
    end

    it "should not notify the author" do
      message = add_message
      message.messages_sent["Conversation Message"].map(&:user_id).should_not be_include(@teacher.id)

      event = add_last_student
      event.messages_sent["Added To Conversation"].map(&:user_id).should_not be_include(@teacher.id)
    end

    it "should not notify unsubscribed participants" do
      student_view = @first_student.conversations.first
      student_view.subscribed = false
      student_view.save

      message = add_message
      message.messages_sent["Conversation Message"].map(&:user_id).should_not be_include(@first_student.id)
    end

    it "should notify subscribed participants on new message" do
      message = add_message
      message.messages_sent["Conversation Message"].map(&:user_id).should be_include(@first_student.id)
    end

    it "should notify new participants" do
      event = add_last_student
      event.messages_sent["Added To Conversation"].map(&:user_id).should be_include(@last_student.id)
    end

    it "should not notify existing participants on added participant" do
      event = add_last_student
      event.messages_sent["Added To Conversation"].map(&:user_id).should_not be_include(@first_student.id)
    end
  end
end
