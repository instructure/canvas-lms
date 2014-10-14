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
    before :once do
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
      user = User.find(@conversation.user_id)
      @account = Account.find(user.account)
      add_message # need initial message for add_participants to not barf
    end

    def add_message(options = {})
      @conversation.add_message("message", options.merge(:root_account_id => @account.id))
    end

    def add_last_student
      @conversation.add_participants([@last_student])
    end

    it "should format an author line with shared contexts" do
      message = add_message
      expect(message.author_short_name_with_shared_contexts(@first_student)).to eq "#{message.author.short_name} (#{@course.name})"
    end

    it "should format an author line without shared contexts" do
      user
      @conversation = @teacher.initiate_conversation([@user])
      message = add_message
      expect(message.author_short_name_with_shared_contexts(@user)).to eq "#{message.author.short_name}"
    end

    it "should create appropriate notifications on new message" do
      message = add_message
      expect(message.messages_sent).to be_include("Conversation Message")
      expect(message.messages_sent).not_to be_include("Added To Conversation")
    end

    it "should create appropriate notifications on added participants" do
      event = add_last_student
      expect(event.messages_sent).not_to be_include("Conversation Message")
      expect(event.messages_sent).to be_include("Added To Conversation")
    end

    it "should not notify the author" do
      message = add_message
      expect(message.messages_sent["Conversation Message"].map(&:user_id)).not_to be_include(@teacher.id)

      event = add_last_student
      expect(event.messages_sent["Added To Conversation"].map(&:user_id)).not_to be_include(@teacher.id)
    end

    it "should not notify unsubscribed participants" do
      student_view = @first_student.conversations.first
      student_view.subscribed = false
      student_view.save

      message = add_message
      expect(message.messages_sent["Conversation Message"].map(&:user_id)).not_to be_include(@first_student.id)
    end

    it "should notify subscribed participants on new message" do
      message = add_message
      expect(message.messages_sent["Conversation Message"].map(&:user_id)).to be_include(@first_student.id)
    end

    it "should limit notifications to message recipients, still excluding the author" do
      message = add_message(only_users: [@teacher, @students.first])
      message_user_ids = message.messages_sent["Conversation Message"].map(&:user_id)
      expect(message_user_ids).not_to include(@teacher.id)
      expect(message_user_ids).to include(@students.first.id)
      @students[1..-1].each do |student|
        expect(message_user_ids).not_to include(student.id)
      end
    end

    it "should notify new participants" do
      event = add_last_student
      expect(event.messages_sent["Added To Conversation"].map(&:user_id)).to be_include(@last_student.id)
    end

    it "should not notify existing participants on added participant" do
      event = add_last_student
      expect(event.messages_sent["Added To Conversation"].map(&:user_id)).not_to be_include(@first_student.id)
    end

    it "should add a new message when a user replies to a notification" do
      conversation_message = add_message
      message = conversation_message.messages_sent["Conversation Message"].first

      expect(message.context).to eq conversation_message
      message.context.reply_from(:user => message.user, :purpose => 'general',
        :subject => message.subject,
        :text => "Reply to notification")
      # The initial message, the one the sent the notification,
      # and the response to the notification
      expect(@conversation.messages.size).to eq 3
      expect(@conversation.messages.first.body).to match(/Reply to notification/)
    end
  end

  context "generate_user_note" do
    it "should add a user note under nominal circumstances" do
      Account.default.update_attribute :enable_user_notes, true
      course_with_teacher(active_all: true)
      student = student_in_course(active_all: true).user
      conversation = @teacher.initiate_conversation([student])
      conversation.add_message("reprimanded!", :generate_user_note => true)
      expect(student.user_notes.size).to be(1)
      note = student.user_notes.first
      expect(note.creator).to eql(@teacher)
      expect(note.title).to eql("Private message")
      expect(note.note).to eql("reprimanded!")
    end

    it "should fail if notes are disabled on the account" do
      Account.default.update_attribute :enable_user_notes, false
      course_with_teacher(active_all: true)
      student = student_in_course(active_all: true).user
      conversation = @teacher.initiate_conversation([student])
      conversation.add_message("reprimanded!", :generate_user_note => true)
      expect(student.user_notes.size).to be(0)
    end

    it "should allow user notes on more than one recipient" do
      Account.default.update_attribute :enable_user_notes, true
      course_with_teacher(active_all: true)
      student1 = student_in_course(active_all: true).user
      student2 = student_in_course(active_all: true).user
      conversation = @teacher.initiate_conversation([student1, student2])
      conversation.add_message("reprimanded!", :generate_user_note => true)
      expect(student1.user_notes.size).to be(1)
      expect(student2.user_notes.size).to be(1)
    end
  end

  context "stream_items" do
    before :once do
      course_with_teacher
      student_in_course
    end

    it "should create a stream item based on the conversation" do
      old_count = StreamItem.count

      conversation = @teacher.initiate_conversation([@user])
      message = conversation.add_message("initial message")

      expect(StreamItem.count).to eql(old_count + 1)
      stream_item = StreamItem.last
      expect(stream_item.asset).to eq message.conversation
    end

    it "should not create a conversation stream item for a submission comment" do
      old_count = StreamItem.count

      assignment_model(:course => @course)
      @assignment.workflow_state = 'published'
      @assignment.save
      @submission = @assignment.submit_homework(@user, :body => 'some message')
      @submission.add_comment(:author => @user, :comment => "hello")

      expect(StreamItem.all.select{ |i| i.asset_string =~ /conversation_/ }).to be_empty
    end

    it "should not create additional stream_items for additional messages in the same conversation" do
      old_count = StreamItem.count

      conversation = @teacher.initiate_conversation([@user])
      conversation.add_message("first message")
      stream_item = StreamItem.last
      conversation.add_message("second message")
      conversation.add_message("third message")

      expect(StreamItem.count).to eql(old_count + 1)
      expect(StreamItem.last).to eql(stream_item)
    end

    it "should not delete the stream_item if a message is deleted, just regenerate" do
      old_count = StreamItem.count

      conversation = @teacher.initiate_conversation([@user])
      conversation.add_message("initial message")
      message = conversation.add_message("second message")

      stream_item = StreamItem.last

      message.destroy
      expect(StreamItem.count).to eql(old_count + 1)
    end

    it "should delete the stream_item if the conversation is deleted" # not yet implemented
  end

  context "infer_defaults" do
    before :once do
      course_with_teacher(:active_all => true)
      student_in_course(:active_all => true)
    end

    it "should set has_attachments if there are attachments" do
      a = attachment_model(:context => @teacher, :folder => @teacher.conversation_attachments_folder)
      m = @teacher.initiate_conversation([@student]).add_message("ohai", :attachment_ids => [a.id])
      expect(m.read_attribute(:has_attachments)).to be_truthy
      expect(m.conversation.reload.has_attachments).to be_truthy
      expect(m.conversation.conversation_participants.all?(&:has_attachments?)).to be_truthy
    end

    it "should set has_attachments if there are forwareded attachments" do
      a = attachment_model(:context => @teacher, :folder => @teacher.conversation_attachments_folder)
      m1 = @teacher.initiate_conversation([user]).add_message("ohai", :attachment_ids => [a.id])
      m2 = @teacher.initiate_conversation([@student]).add_message("lulz", :forwarded_message_ids => [m1.id])
      expect(m2.read_attribute(:has_attachments)).to be_truthy
      expect(m2.conversation.reload.has_attachments).to be_truthy
      expect(m2.conversation.conversation_participants.all?(&:has_attachments?)).to be_truthy
    end

    it "should set has_media_objects if there is a media comment" do
      mc = MediaObject.new
      mc.media_type = 'audio'
      mc.media_id = 'asdf'
      mc.context = mc.user = @teacher
      mc.save
      m = @teacher.initiate_conversation([@student]).add_message("ohai", :media_comment => mc)
      expect(m.read_attribute(:has_media_objects)).to be_truthy
      expect(m.conversation.reload.has_media_objects).to be_truthy
      expect(m.conversation.conversation_participants.all?(&:has_media_objects?)).to be_truthy
    end

    it "should set has_media_objects if there are forwarded media comments" do
      mc = MediaObject.new
      mc.media_type = 'audio'
      mc.media_id = 'asdf'
      mc.context = mc.user = @teacher
      mc.save
      m1 = @teacher.initiate_conversation([user]).add_message("ohai", :media_comment => mc)
      m2 = @teacher.initiate_conversation([@student]).add_message("lulz", :forwarded_message_ids => [m1.id])
      expect(m2.read_attribute(:has_media_objects)).to be_truthy
      expect(m2.conversation.reload.has_media_objects).to be_truthy
      expect(m2.conversation.conversation_participants.all?(&:has_media_objects?)).to be_truthy
    end
  end

  describe "reply_from" do
    before :once do
      course_with_teacher
    end

    it "should ignore replies on deleted accounts" do
      student_in_course
      conversation = @teacher.initiate_conversation([@user])
      cm = conversation.add_message("initial message", :root_account_id => Account.default.id)

      Account.default.destroy
      cm.reload

      expect { cm.reply_from({
        :purpose => 'general',
        :user => @teacher,
        :subject => "an email reply",
        :html => "body",
        :text => "body"
      }) }.to raise_error(IncomingMail::Errors::UnknownAddress)
    end

    it "should reply only to the message author on conversations2 conversations" do
      users = 3.times.map{ course_with_student(course: @course).user }
      conversation = Conversation.initiate(users, false, :context_type => 'Course', :context_id => @course.id)
      cm1 = conversation.add_message(users[0], "initial message", :root_account_id => Account.default.id)
      cm2 = conversation.add_message(users[1], "subsequent message", :root_account_id => Account.default.id)
      expect(cm2.conversation_message_participants.size).to eq 3
      cm3 = cm2.reply_from({
        :purpose => 'general',
        :user => users[2],
        :subject => "an email reply",
        :html => "body",
        :text => "body"
      })
      expect(cm3.conversation_message_participants.size).to eq 2
      expect(cm3.conversation_message_participants.map{|x| x.user_id}.sort).to eq [users[1].id, users[2].id].sort
    end

    it "should mark conversations as read for the replying author" do
      student_in_course
      cp = @teacher.initiate_conversation([@user])
      cm = cp.add_message("initial message", :root_account_id => Account.default.id)

      cp2 = cp.conversation.conversation_participants.where(user_id: @user).first
      expect(cp2.workflow_state).to eq 'unread'
      cm.reply_from({
        :purpose => 'general',
        :user => @user,
        :subject => "an email reply",
        :html => "body",
        :text => "body"
      })
      cp2.reload
      expect(cp2.workflow_state).to eq 'read'
    end
  end
end
