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

      @conversation = @teacher.initiate_conversation(@initial_students)
      add_message # need initial message for add_participants to not barf
    end

    def add_message(options = {})
      @conversation.add_message("message", options)
    end

    def add_last_student
      @conversation.add_participants([@last_student])
    end

    it "should format an author line with shared contexts" do
      message = add_message
      message.author_short_name_with_shared_contexts(@first_student).should == "#{message.author.short_name} (#{@course.name})"
    end

    it "should format an author line without shared contexts" do
      user
      @conversation = @teacher.initiate_conversation([@user])
      message = add_message
      message.author_short_name_with_shared_contexts(@user).should == "#{message.author.short_name}"
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

    it "should limit notifications to message recipients, still excluding the author" do
      message = add_message(only_users: [@teacher, @students.first])
      message_user_ids = message.messages_sent["Conversation Message"].map(&:user_id)
      message_user_ids.should_not include(@teacher.id)
      message_user_ids.should include(@students.first.id)
      @students[1..-1].each do |student|
        message_user_ids.should_not include(student.id)
      end
    end

    it "should notify new participants" do
      event = add_last_student
      event.messages_sent["Added To Conversation"].map(&:user_id).should be_include(@last_student.id)
    end

    it "should not notify existing participants on added participant" do
      event = add_last_student
      event.messages_sent["Added To Conversation"].map(&:user_id).should_not be_include(@first_student.id)
    end

    it "should add a new message when a user replies to a notification" do
      conversation_message = add_message
      message = conversation_message.messages_sent["Conversation Message"].first

      message.context.should == conversation_message
      message.context.reply_from(:user => message.user, :purpose => 'general',
        :subject => message.subject,
        :text => "Reply to notification")
      # The initial message, the one the sent the notification,
      # and the response to the notification
      @conversation.messages.size.should == 3
      @conversation.messages.first.body.should match(/Reply to notification/)
    end
  end

  context "generate_user_note" do
    it "should add a user note under nominal circumstances" do
      Account.default.update_attribute :enable_user_notes, true
      course_with_teacher
      student = student_in_course.user
      conversation = @teacher.initiate_conversation([student])
      conversation.add_message("reprimanded!", :generate_user_note => true)
      student.user_notes.size.should be(1)
      note = student.user_notes.first
      note.creator.should eql(@teacher)
      note.title.should eql("Private message")
      note.note.should eql("reprimanded!")
    end

    it "should fail if notes are disabled on the account" do
      Account.default.update_attribute :enable_user_notes, false
      course_with_teacher
      student = student_in_course.user
      conversation = @teacher.initiate_conversation([student])
      conversation.add_message("reprimanded!", :generate_user_note => true)
      student.user_notes.size.should be(0)
    end

    it "should fail if there's more than one recipient" do
      Account.default.update_attribute :enable_user_notes, true
      course_with_teacher
      student1 = student_in_course.user
      student2 = student_in_course.user
      conversation = @teacher.initiate_conversation([student1, student2])
      conversation.add_message("reprimanded!", :generate_user_note => true)
      student1.user_notes.size.should be(0)
      student2.user_notes.size.should be(0)
    end
  end

  context "stream_items" do
    it "should create a stream item based on the conversation" do
      old_count = StreamItem.count

      course_with_teacher
      student_in_course
      conversation = @teacher.initiate_conversation([@user])
      message = conversation.add_message("initial message")

      StreamItem.count.should eql(old_count + 1)
      stream_item = StreamItem.last
      stream_item.asset.should == message.conversation
    end

    it "should not create a conversation stream item for a submission comment" do
      old_count = StreamItem.count

      course_with_teacher
      student_in_course.user
      assignment_model(:course => @course)
      @assignment.workflow_state = 'published'
      @assignment.save
      @submission = @assignment.submit_homework(@user, :body => 'some message')
      @submission.add_comment(:author => @user, :comment => "hello")

      StreamItem.all.select{ |i| i.asset_string =~ /conversation_/ }.should be_empty
    end

    it "should not create additional stream_items for additional messages in the same conversation" do
      old_count = StreamItem.count

      course_with_teacher
      student_in_course
      conversation = @teacher.initiate_conversation([@user])
      conversation.add_message("first message")
      stream_item = StreamItem.last
      conversation.add_message("second message")
      conversation.add_message("third message")

      StreamItem.count.should eql(old_count + 1)
      StreamItem.last.should eql(stream_item)
    end

    it "should not delete the stream_item if a message is deleted, just regenerate" do
      old_count = StreamItem.count

      course_with_teacher
      student_in_course
      conversation = @teacher.initiate_conversation([@user])
      conversation.add_message("initial message")
      message = conversation.add_message("second message")

      stream_item = StreamItem.last

      message.destroy
      StreamItem.count.should eql(old_count + 1)
    end

    it "should delete the stream_item if the conversation is deleted" # not yet implemented
  end

  context "infer_defaults" do
    before do
      course_with_teacher(:active_all => true)
      student_in_course(:active_all => true)
    end

    it "should set has_attachments if there are attachments" do
      a = attachment_model(:context => @teacher, :folder => @teacher.conversation_attachments_folder)
      m = @teacher.initiate_conversation([@student]).add_message("ohai", :attachment_ids => [a.id])
      m.read_attribute(:has_attachments).should be_true
      m.conversation.reload.has_attachments.should be_true
      m.conversation.conversation_participants.all?(&:has_attachments?).should be_true
    end

    it "should set has_attachments if there are forwareded attachments" do
      a = attachment_model(:context => @teacher, :folder => @teacher.conversation_attachments_folder)
      m1 = @teacher.initiate_conversation([user]).add_message("ohai", :attachment_ids => [a.id])
      m2 = @teacher.initiate_conversation([@student]).add_message("lulz", :forwarded_message_ids => [m1.id])
      m2.read_attribute(:has_attachments).should be_true
      m2.conversation.reload.has_attachments.should be_true
      m2.conversation.conversation_participants.all?(&:has_attachments?).should be_true
    end

    it "should set has_media_objects if there is a media comment" do
      mc = MediaObject.new
      mc.media_type = 'audio'
      mc.media_id = 'asdf'
      mc.context = mc.user = @teacher
      mc.save
      m = @teacher.initiate_conversation([@student]).add_message("ohai", :media_comment => mc)
      m.read_attribute(:has_media_objects).should be_true
      m.conversation.reload.has_media_objects.should be_true
      m.conversation.conversation_participants.all?(&:has_media_objects?).should be_true
    end

    it "should set has_media_objects if there are forwarded media comments" do
      mc = MediaObject.new
      mc.media_type = 'audio'
      mc.media_id = 'asdf'
      mc.context = mc.user = @teacher
      mc.save
      m1 = @teacher.initiate_conversation([user]).add_message("ohai", :media_comment => mc)
      m2 = @teacher.initiate_conversation([@student]).add_message("lulz", :forwarded_message_ids => [m1.id])
      m2.read_attribute(:has_media_objects).should be_true
      m2.conversation.reload.has_media_objects.should be_true
      m2.conversation.conversation_participants.all?(&:has_media_objects?).should be_true
    end
  end

  describe "reply_from" do
    it "should ignore replies on deleted accounts" do
      course_with_teacher
      student_in_course
      conversation = @teacher.initiate_conversation([@user])
      cm = conversation.add_message("initial message", :root_account_id => Account.default.id)

      Account.default.destroy
      cm.reload

      lambda { cm.reply_from({
        :purpose => 'general',
        :user => @teacher,
        :subject => "an email reply",
        :html => "body",
        :text => "body"
      }) }.should raise_error(IncomingMail::IncomingMessageProcessor::UnknownAddressError)
    end

    it "should reply only to the message author on conversations2 conversations" do
      course_with_teacher
      users = 3.times.map{ course_with_student(course: @course).user }
      conversation = Conversation.initiate(users, false, :context_type => 'Course', :context_id => @course.id)
      cm1 = conversation.add_message(users[0], "initial message", :root_account_id => Account.default.id)
      cm2 = conversation.add_message(users[1], "subsequent message", :root_account_id => Account.default.id)
      cm2.conversation_message_participants.size.should == 3
      cm3 = cm2.reply_from({
        :purpose => 'general',
        :user => users[2],
        :subject => "an email reply",
        :html => "body",
        :text => "body"
      })
      cm3.conversation_message_participants.size.should == 2
      cm3.conversation_message_participants.map{|x| x.user_id}.sort.should == [users[1].id, users[2].id].sort
    end
  end
end
