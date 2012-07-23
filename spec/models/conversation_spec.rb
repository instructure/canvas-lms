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

describe Conversation do
  context "initiation" do
    it "should set private_hash for private conversations" do
      users = 2.times.map{ user }
      Conversation.initiate(users.map(&:id), true).private_hash.should_not be_nil
    end

    it "should not set private_hash for group conversations" do
      users = 3.times.map{ user }
      Conversation.initiate(users.map(&:id), false).private_hash.should be_nil
    end

    it "should reuse private conversations" do
      users = 2.times.map{ user }
      Conversation.initiate(users.map(&:id), true).should ==
      Conversation.initiate(users.map(&:id), true)
    end

    it "should not reuse group conversations" do
      users = 2.times.map{ user }
      Conversation.initiate(users.map(&:id), false).should_not ==
      Conversation.initiate(users.map(&:id), false)
    end
  end

  context "adding participants" do
    it "should not add participants to private conversations" do
      sender = user
      root_convo = Conversation.initiate([sender.id, user.id], true)
      lambda{ root_convo.add_participants(sender, [user.id]) }.should raise_error
    end

    it "should add new participants to group conversations and give them all messages" do
      sender = user
      root_convo = Conversation.initiate([sender.id, user.id], false)
      root_convo.add_message(sender, 'test')

      new_guy = user
      lambda{ root_convo.add_participants(sender, [new_guy.id]) }.should_not raise_error
      root_convo.participants.size.should == 3

      convo = new_guy.conversations.first
      convo.unread?.should be_true
      convo.messages.size.should == 2 # the test message plus a "user was added" message
      convo.participants.size.should == 3 # includes the sender (though we don't show him in the ui)
    end

    it "should not re-add existing participants to group conversations" do
      sender = user
      recipient = user
      root_convo = Conversation.initiate([sender.id, recipient.id], false)
      lambda{ root_convo.add_participants(sender, [recipient.id]) }.should_not raise_error
      root_convo.participants.size.should == 2
    end

    it "should update the updated_at timestamp and clear the identity header cache of new participants" do
      sender = user
      root_convo = Conversation.initiate([sender.id, user.id], false)
      root_convo.add_message(sender, 'test')

      new_guy = user
      old_updated_at = new_guy.updated_at
      root_convo.add_participants(sender, [new_guy.id])
      new_guy.reload.updated_at.should_not eql old_updated_at
    end
  end

  context "message counts" do
    it "should increment when adding messages" do
      sender = user
      recipient = user
      Conversation.initiate([sender.id, recipient.id], false).add_message(sender, 'test')
      sender.conversations.first.message_count.should eql 1
      recipient.conversations.first.message_count.should eql 1
    end

    it "should decrement when removing messages" do
      sender = user
      recipient = user
      root_convo = Conversation.initiate([sender.id, recipient.id], false)
      root_convo.add_message(sender, 'test')
      msg = root_convo.add_message(sender, 'test2')
      sender.conversations.first.message_count.should eql 2
      recipient.conversations.first.message_count.should eql 2

      sender.conversations.first.remove_messages(msg)
      sender.conversations.first.reload.message_count.should eql 1
      recipient.conversations.first.reload.message_count.should eql 2
    end
  end

  context "unread counts" do
    it "should increment for recipients when sending the first message in a conversation" do
      sender = user
      recipient = user
      root_convo = Conversation.initiate([sender.id, recipient.id], false)
      ConversationParticipant.unread.size.should eql 0 # only once the first message is added
      root_convo.add_message(sender, 'test')
      sender.reload.unread_conversations_count.should eql 0
      sender.conversations.unread.size.should eql 0
      recipient.reload.unread_conversations_count.should eql 1
      recipient.conversations.unread.size.should eql 1
    end

    it "should increment for subscribed recipients when adding a message to a read conversation" do
      sender = user
      unread_guy = user
      subscribed_guy = user
      unsubscribed_guy = user
      root_convo = Conversation.initiate([sender.id, unread_guy.id, subscribed_guy.id, unsubscribed_guy.id], false)
      root_convo.add_message(sender, 'test')

      unread_guy.reload.unread_conversations_count.should eql 1
      unread_guy.conversations.unread.size.should eql 1
      subscribed_guy.conversations.first.update_attribute(:workflow_state, "read")
      subscribed_guy.reload.unread_conversations_count.should eql 0
      subscribed_guy.conversations.unread.size.should eql 0
      unsubscribed_guy.conversations.first.update_attributes(:subscribed => false)
      unsubscribed_guy.reload.unread_conversations_count.should eql 0
      unsubscribed_guy.conversations.unread.size.should eql 0

      root_convo.add_message(sender, 'test2')

      unread_guy.reload.unread_conversations_count.should eql 1
      unread_guy.conversations.unread.size.should eql 1
      subscribed_guy.reload.unread_conversations_count.should eql 1
      subscribed_guy.conversations.unread.size.should eql 1
      unsubscribed_guy.reload.unread_conversations_count.should eql 0
      unsubscribed_guy.conversations.unread.size.should eql 0
    end

    it "should decrement when deleting an unread conversation" do
      sender = user
      unread_guy = user
      root_convo = Conversation.initiate([sender.id, unread_guy.id], false)
      root_convo.add_message(sender, 'test')

      unread_guy.reload.unread_conversations_count.should eql 1
      unread_guy.conversations.unread.size.should eql 1
      unread_guy.conversations.first.remove_messages(:all)
      unread_guy.reload.unread_conversations_count.should eql 0
      unread_guy.conversations.unread.size.should eql 0
    end

    it "should decrement when marking as read" do
      sender = user
      unread_guy = user
      root_convo = Conversation.initiate([sender.id, unread_guy.id], false)
      root_convo.add_message(sender, 'test')

      unread_guy.reload.unread_conversations_count.should eql 1
      unread_guy.conversations.unread.size.should eql 1
      unread_guy.conversations.first.update_attribute(:workflow_state, "read")
      unread_guy.reload.unread_conversations_count.should eql 0
      unread_guy.conversations.unread.size.should eql 0
    end

    it "should indecrement when marking as unread" do
      sender = user
      unread_guy = user
      root_convo = Conversation.initiate([sender.id, unread_guy.id], false)
      root_convo.add_message(sender, 'test')
      unread_guy.conversations.first.update_attribute(:workflow_state, "read")

      unread_guy.reload.unread_conversations_count.should eql 0
      unread_guy.conversations.unread.size.should eql 0
      unread_guy.conversations.first.update_attribute(:workflow_state, "unread")
      unread_guy.reload.unread_conversations_count.should eql 1
      unread_guy.conversations.unread.size.should eql 1
    end
  end

  context "subscription" do
    it "should mark-as-read when unsubscribing iff it was unread" do
      sender = user
      subscription_guy = user
      archive_guy = user
      root_convo = Conversation.initiate([sender.id, archive_guy.id, subscription_guy.id], false)
      root_convo.add_message(sender, 'test')

      subscription_guy.reload.unread_conversations_count.should eql 1
      subscription_guy.conversations.unread.size.should eql 1

      subscription_guy.conversations.first.update_attributes(:subscribed => false)
      subscription_guy.reload.unread_conversations_count.should eql 0
      subscription_guy.conversations.unread.size.should eql 0

      archive_guy.conversations.first.update_attributes(:workflow_state => "archived", :subscribed => false)
      archive_guy.conversations.archived.size.should eql 1
    end

    it "should mark-as-unread when re-subscribing iff there are newer messages" do
      sender = user
      flip_flopper_guy = user
      subscription_guy = user
      archive_guy = user
      root_convo = Conversation.initiate([sender.id, flip_flopper_guy.id, archive_guy.id, subscription_guy.id], false)
      root_convo.add_message(sender, 'test')

      flip_flopper_guy.conversations.first.update_attributes(:subscribed => false)
      flip_flopper_guy.reload.unread_conversations_count.should eql 0
      flip_flopper_guy.conversations.unread.size.should eql 0
      # no new messages in the interim, he should stay "marked-as-read"
      flip_flopper_guy.conversations.first.update_attributes(:subscribed => true)
      flip_flopper_guy.reload.unread_conversations_count.should eql 0
      flip_flopper_guy.conversations.unread.size.should eql 0

      subscription_guy.conversations.first.update_attributes(:subscribed => false)
      archive_guy.conversations.first.update_attributes(:workflow_state => "archived", :subscribed => false)

      message = root_convo.add_message(sender, 'you wish you were subscribed!')
      message.update_attribute(:created_at, Time.now.utc + 1.minute)
      last_message_at = message.reload.created_at

      subscription_guy.conversations.first.update_attributes(:subscribed => true)
      archive_guy.conversations.first.update_attributes(:subscribed => true)

      subscription_guy.reload.unread_conversations_count.should eql 1
      subscription_guy.conversations.unread.size.should eql 1
      subscription_guy.conversations.first.last_message_at.should eql last_message_at

      archive_guy.reload.unread_conversations_count.should eql 1
      archive_guy.conversations.unread.size.should eql 1
      subscription_guy.conversations.first.last_message_at.should eql last_message_at
    end

    it "should not toggle read/unread until the subscription change is saved" do
      sender = user
      subscription_guy = user
      root_convo = Conversation.initiate([sender.id, user.id, subscription_guy.id], false)
      root_convo.add_message(sender, 'test')

      subscription_guy.reload.unread_conversations_count.should eql 1
      subscription_guy.conversations.unread.size.should eql 1

      subscription_guy.conversations.first.subscribed = false
      subscription_guy.reload.unread_conversations_count.should eql 1
      subscription_guy.conversations.unread.size.should eql 1

      subscription_guy.conversations.first.subscribed = true
      subscription_guy.reload.unread_conversations_count.should eql 1
      subscription_guy.conversations.unread.size.should eql 1
    end
  end

  context "adding messages" do
    it "should deliver the message to all participants" do
      sender = user
      recipients = 5.times.map{ user }
      Conversation.initiate([sender.id] + recipients.map(&:id), false).add_message(sender, 'test')
      convo = sender.conversations.first
      convo.reload.read?.should be_true # only for the sender, and then only on the first message
      convo.messages.size.should == 1
      convo.messages.first.body.should == 'test'
      recipients.each do |recipient|
        convo = recipient.conversations.first
        convo.read?.should be_false
        convo.messages.size.should == 1
        convo.messages.first.body.should == 'test'
      end
    end

    it "should only ever change the workflow_state for the sender if it's archived and it's a direct message (not bulk)" do
      sender = user
      Conversation.initiate([sender.id, user.id], true).add_message(sender, 'test')
      convo = sender.conversations.first
      convo.update_attribute(:workflow_state, "unread")
      convo.add_message('another test', :update_for_sender => false) # as if it were a bulk private message
      convo.reload.unread?.should be_true

      convo.update_attribute(:workflow_state, "archived")
      convo.add_message('one more test', :update_for_sender => false)
      convo.reload.archived?.should be_true

      convo.update_attribute(:workflow_state, "unread")
      convo.add_message('and another test') # overrides subscribed-ness and updates timestamps
      convo.reload.unread?.should be_true

      convo.update_attribute(:workflow_state, "archived")
      convo.add_message('last one')
      convo.reload.archived?.should be_false
      convo.reload.read?.should be_true
    end

    it "should not set last_message_at for the sender if the conversation is deleted and update_for_sender=false" do
      sender = user
      rconvo = Conversation.initiate([sender.id, user.id], true)
      message = rconvo.add_message(sender, 'test')
      convo = sender.conversations.first
      convo.last_message_at.should_not be_nil

      convo.remove_messages([message])
      convo.last_message_at.should be_nil

      convo.add_message('bulk message', :update_for_sender => false)
      convo.reload
      convo.last_message_at.should be_nil
    end

    it "should set last_authored_at and visible_last_authored_at on deleted conversations even if update_for_sender=false" do
      expected_times = [Time.now.utc - 1.hours, Time.now.utc].map{ |t| Time.parse(t.to_s) }
      ConversationMessage.any_instance.expects(:current_time_from_proper_timezone).twice.returns(*expected_times)

      sender = user
      rconvo = Conversation.initiate([sender.id, user.id], true)
      message = rconvo.add_message(sender, 'test')
      convo = sender.conversations.first
      convo.last_authored_at.should eql expected_times.first
      convo.visible_last_authored_at.should eql expected_times.first

      convo.remove_messages([message])
      convo.last_authored_at.should eql expected_times.first
      convo.visible_last_authored_at.should be_nil

      convo.add_message('bulk message', :update_for_sender => false)
      convo.reload
      convo.last_authored_at.should eql expected_times.last
      convo.visible_last_authored_at.should eql expected_times.last
    end

    it "should deliver the message to unsubscribed participants but not alert them" do
      sender = user
      recipients = 5.times.map{ user }
      Conversation.initiate([sender.id] + recipients.map(&:id), false).add_message(sender, 'test')

      recipient = recipients.last
      rconvo = recipient.conversations.first
      rconvo.unread?.should be_true
      rconvo.update_attributes(:subscribed => false)
      rconvo.unread?.should be_false

      convo = sender.conversations.first
      message = convo.add_message('another test')
      message.update_attribute(:created_at, Time.now.utc + 1.minute)

      rconvo.reload.unread?.should be_false
      rconvo.update_attributes(:subscribed => true)
      rconvo.unread?.should be_true
    end
  end

  context "update_all_for_asset" do
    it "should delete all messages if requested" do
      asset = mock
      asset_messages = mock
      asset_messages.expects(:destroy_all).returns([])
      asset.expects(:lock!).returns(true)
      asset.expects(:conversation_messages).at_least_once.returns(asset_messages)
      Conversation.update_all_for_asset asset, :delete_all => true
    end

    it "should not create conversations if only_existing is set" do
      u1 = user
      u2 = user
      conversation = Conversation.initiate([u1.id, u2.id], true)
      asset = Submission.new(:user => u1)
      asset.expects(:conversation_groups).returns([[u1.id, u2.id]])
      asset.expects(:lock!).returns(true)
      asset.expects(:conversation_messages).at_least_once.returns([])
      asset.expects(:conversation_message_data).returns({:created_at => Time.now.utc, :author_id => u1.id, :body => "asdf"})
      Conversation.update_all_for_asset asset, :update_message => true, :only_existing => true
      conversation.conversation_messages.size.should eql 1
    end

    it "should create conversations by default" do
      u1 = user
      u2 = user
      conversation = Conversation.initiate([u1.id, u2.id], true)
      asset = Submission.new(:user => u1)
      asset.expects(:conversation_groups).returns([[u1.id, u2.id]])
      asset.expects(:lock!).returns(true)
      asset.expects(:conversation_messages).at_least_once.returns([])
      asset.expects(:conversation_message_data).returns({:created_at => Time.now.utc, :author_id => u1.id, :body => "asdf"})
      Conversation.expects(:initiate).returns(conversation)
      Conversation.update_all_for_asset asset, :update_message => true
      conversation.conversation_messages.size.should eql 1
    end

    it "should delete obsolete messages" do
      old_message = mock
      old_message.expects(:destroy).returns(true)
      asset = mock
      asset.expects(:lock!).returns(true)
      asset.expects(:conversation_groups).returns([])
      asset.expects(:conversation_messages).at_least_once.returns([old_message])
      Conversation.update_all_for_asset(asset, {})
    end
  end

  context "context tags" do
    context "current_context_strings" do
      it "should not double-count duplicate enrollments" do
        u1 = student_in_course(:active_all => true).user
        u2 = student_in_course(:active_all => true).user
        course1 = @course

        course_with_student(:active_all => true, :user => u1)
        course2 = @course
        other_section = course2.course_sections.create
        course2.enroll_student(u1, :allow_multiple_enrollments => true, :section => other_section)
        u1.enrollments.size.should eql 3

        conversation = Conversation.initiate([u1.id, u2.id], true)

        conversation.current_context_strings(1).should eql [course1.asset_string]
        u1.conversation_context_codes.sort.should eql [course1.asset_string, course2.asset_string].sort # just once
      end
    end

    context "initial tags" do
      it "should save all valid tags on the conversation" do # NOTE: this will change if/when we allow arbitrary tags
        u1 = student_in_course(:active_all => true).user
        u2 = student_in_course(:active_all => true, :course => @course).user
        conversation = Conversation.initiate([u1.id, u2.id], true)
        conversation.add_message(u1, 'test', :tags => [@course.asset_string, "asdf", "lol"])
        conversation.tags.should eql [@course.asset_string]
      end

      it "should set initial empty tags on the conversation and conversation_participant" do
        u1 = student_in_course.user
        u2 = student_in_course(:course => @course).user
        conversation = Conversation.initiate([u1.id, u2.id], true)
        conversation.read_attribute(:tags).should_not be_nil
        conversation.tags.should eql []
        u1.all_conversations.first.read_attribute(:tags).should_not be_nil
        u1.all_conversations.first.tags.should eql []
        u2.all_conversations.first.read_attribute(:tags).should_not be_nil
        u2.all_conversations.first.tags.should eql []
      end

      it "should ignore explicit context tags not shared by at least two participants" do
        u1 = student_in_course(:active_all => true).user
        u2 = student_in_course(:active_all => true, :course => @course).user
        u3 = user
        @course1 = @course
        @course2 = course(:active_all => true)
        @course2.enroll_student(u1).update_attribute(:workflow_state, 'active')
        conversation = Conversation.initiate([u1.id, u2.id, u3.id], false)
        conversation.add_message(u1, 'test', :tags => [@course1.asset_string, @course2.asset_string])
        conversation.tags.should eql [@course1.asset_string]
      end

      it "should save all visible tags on the conversation_participant" do
        u1 = student_in_course(:active_all => true).user
        u2 = student_in_course(:active_all => true, :course => @course).user
        u3 = user
        conversation = Conversation.initiate([u1.id, u2.id, u3.id], false)
        conversation.add_message(u1, 'test', :tags => [@course.asset_string])
        conversation.tags.should eql [@course.asset_string]
        u1.conversations.first.tags.should eql [@course.asset_string]
        u2.conversations.first.tags.should eql [@course.asset_string]
        u3.conversations.first.tags.should eql []
      end

      it "should default all tags to common ones over the 50% threshold if none are specified" do
        u1 = student_in_course(:active_all => true).user
        u2 = student_in_course(:active_all => true, :course => @course).user
        @course1 = @course
        @course2 = course(:active_all => true)
        @course2.enroll_student(u2).update_attribute(:workflow_state, 'active')
        u3 = student_in_course(:active_all => true, :course => @course2).user
        conversation = Conversation.initiate([u1.id, u2.id, u3.id], false)
        conversation.add_message(u1, 'test')
        conversation.tags.sort.should eql [@course1.asset_string, @course2.asset_string].sort
        u1.conversations.first.tags.should eql [@course1.asset_string]
        u2.conversations.first.tags.sort.should eql [@course1.asset_string, @course2.asset_string].sort
        u3.conversations.first.tags.should eql [@course2.asset_string]
      end

      it "should default the conversation_participant tags to common ones over the 50% threshold if no specified tags match" do
        u1 = student_in_course(:active_all => true).user
        u2 = student_in_course(:active_all => true, :course => @course).user
        @course1 = @course
        @course2 = course(:active_all => true)
        @course2.enroll_student(u2).update_attribute(:workflow_state, 'active')
        u3 = student_in_course(:active_all => true, :course => @course2).user
        conversation = Conversation.initiate([u1.id, u2.id, u3.id], false)
        conversation.add_message(u1, 'test', :tags => [@course1.asset_string])
        conversation.tags.should eql [@course1.asset_string]
        u1.conversations.first.tags.should eql [@course1.asset_string]
        u2.conversations.first.tags.should eql [@course1.asset_string] # just the one, since it was explicit
        u3.conversations.first.tags.should eql [@course2.asset_string] # not in course1, so fall back to common ones (i.e. course2)
      end
    end

    context "deletion" do
      it "should remove tags when all messages are deleted" do
        u1 = student_in_course(:active_all => true).user
        u2 = student_in_course(:active_all => true, :course => @course).user
        conversation = Conversation.initiate([u1.id, u2.id], true)
        conversation.add_message(u1, 'test')
        conversation.tags.should eql [@course.asset_string]
        cp1 = u1.conversations.first
        cp1.tags.should eql [@course.asset_string]
        cp2 = u2.conversations.first
        cp2.tags.should eql [@course.asset_string]

        cp2.remove_messages(:all)
        cp2.tags.should eql []
        
        # no change here
        cp1.reload.tags.should eql [@course.asset_string]
        conversation.reload.tags.should eql [@course.asset_string]
      end
    end

    context "subsequent tags" do
      it "should add new tags to the conversation" do
        u1 = student_in_course(:active_all => true).user
        u2 = student_in_course(:active_all => true, :course => @course).user
        @course1 = @course
        @course2 = course(:active_all => true)
        @course2.enroll_student(u2).update_attribute(:workflow_state, 'active')
        u3 = student_in_course(:active_all => true, :course => @course2).user
        conversation = Conversation.initiate([u1.id, u2.id, u3.id], false)
        conversation.add_message(u1, 'test', :tags => [@course1.asset_string])
        conversation.tags.should eql [@course1.asset_string]

        conversation.add_message(u1, 'another', :tags => [@course2.asset_string])
        conversation.tags.sort.should eql [@course1.asset_string, @course2.asset_string].sort
      end

      it "should add new visible tags to the conversation_participant" do
        u1 = student_in_course(:active_all => true).user
        u2 = student_in_course(:active_all => true, :course => @course).user
        @course1 = @course
        @course2 = course(:active_all => true)
        @course2.enroll_student(u2).update_attribute(:workflow_state, 'active')
        u3 = student_in_course(:active_all => true, :course => @course2).user
        conversation = Conversation.initiate([u1.id, u2.id, u3.id], false)
        conversation.add_message(u1, 'test', :tags => [@course1.asset_string])
        u1.conversations.first.tags.should eql [@course1.asset_string]
        u2.conversations.first.tags.should eql [@course1.asset_string]
        u3.conversations.first.tags.should eql [@course2.asset_string]

        conversation.add_message(u1, 'another', :tags => [@course2.asset_string, "course_0"])
        u1.conversations.first.tags.should eql [@course1.asset_string]
        u2.conversations.first.tags.sort.should eql [@course1.asset_string, @course2.asset_string].sort
        u3.conversations.first.tags.should eql [@course2.asset_string]
      end

      it "should ignore conversation_participants without a valid user" do
        u1 = student_in_course(:active_all => true).user
        u2 = student_in_course(:active_all => true, :course => @course).user
        @course1 = @course
        @course2 = course(:active_all => true)
        @course2.enroll_student(u2).update_attribute(:workflow_state, 'active')
        u3 = student_in_course(:active_all => true, :course => @course2).user
        conversation = Conversation.initiate([u1.id, u2.id, u3.id], false)
        conversation.add_message(u1, 'test', :tags => [@course1.asset_string])
        u1.conversations.first.tags.should eql [@course1.asset_string]
        u2.conversations.first.tags.should eql [@course1.asset_string]
        u3.conversations.first.tags.should eql [@course2.asset_string]
        broken_one = u3.conversations.first
        broken_one.user_id = nil
        broken_one.tags = []
        broken_one.save!

        conversation.add_message(u1, 'another', :tags => [@course2.asset_string, "course_0"])
        u1.conversations.first.tags.should eql [@course1.asset_string]
        u2.conversations.first.tags.sort.should eql [@course1.asset_string, @course2.asset_string].sort
        broken_one.reload.tags.should eql []
      end
    end

    context "private conversations" do
      it "should save new visible tags on the conversation_message_participant" do
        u1 = student_in_course(:active_all => true).user
        u2 = student_in_course(:active_all => true, :course => @course).user
        @course1 = @course
        @course2 = course(:active_all => true)
        @course2.enroll_student(u1).update_attribute(:workflow_state, 'active')
        @course2.enroll_student(u2).update_attribute(:workflow_state, 'active')
        conversation = Conversation.initiate([u1.id, u2.id], true)
        conversation.add_message(u1, 'test', :tags => [@course1.asset_string])
        cp = u2.conversations.first
        cp.messages.human.first.tags.should eql [@course1.asset_string]

        conversation.add_message(u1, 'another', :tags => [@course2.asset_string, "course_0"])
        cp.messages.human.first.tags.should eql [@course2.asset_string]
      end

      it "should save the previous message tags on the conversation_message_participant if there are no new visible ones" do
        u1 = student_in_course(:active_all => true).user
        u2 = student_in_course(:active_all => true, :course => @course).user
        conversation = Conversation.initiate([u1.id, u2.id], true)
        conversation.add_message(u1, 'test', :tags => [@course.asset_string])
        cp = u2.conversations.first
        cp.messages.human.first.tags.should eql [@course.asset_string]

        conversation.add_message(u1, 'another', :tags => ["course_0"])
        cp.messages.human.first.tags.should eql [@course.asset_string]
      end

      it "should recompute the conversation_participant's tags when removing messages" do
        u1 = student_in_course(:active_all => true).user
        u2 = student_in_course(:active_all => true, :course => @course).user
        @course1 = @course
        @course2 = course(:active_all => true)
        @course2.enroll_student(u1).update_attribute(:workflow_state, 'active')
        @course2.enroll_student(u2).update_attribute(:workflow_state, 'active')
        conversation = Conversation.initiate([u1.id, u2.id], true)
        conversation.add_message(u1, 'test', :tags => [@course1.asset_string])
        cp = u2.conversations.first
        cp.tags.should eql [@course1.asset_string]
        cp.messages.human.first.tags.should eql [@course1.asset_string]

        conversation.add_message(u1, 'another', :tags => [@course2.asset_string])
        cp.reload.tags.sort.should eql [@course1.asset_string, @course2.asset_string].sort
        cp.messages.human.first.tags.should eql [@course2.asset_string]

        cp.remove_messages(cp.messages.human.first)
        cp.reload.tags.should eql [@course1.asset_string]
      end
    end

    context "group conversations" do
      it "should not save tags on the conversation_message_participant" do
        u1 = student_in_course(:active_all => true).user
        u2 = student_in_course(:active_all => true, :course => @course).user
        u3 = student_in_course(:active_all => true, :course => @course).user
        @course = @course
        conversation = Conversation.initiate([u1.id, u2.id, u3.id], false)
        conversation.add_message(u1, 'test', :tags => [@course.asset_string])
        u1.conversations.first.messages.human.first.tags.should eql []
        u2.conversations.first.messages.human.first.tags.should eql []
        u3.conversations.first.messages.human.first.tags.should eql []
      end

      it "should not recompute the conversation_participant's tags when removing messages" do
        u1 = student_in_course(:active_all => true).user
        u2 = student_in_course(:active_all => true, :course => @course).user
        @course1 = @course
        @course2 = course(:active_all => true)
        @course2.enroll_student(u2).update_attribute(:workflow_state, 'active')
        u3 = student_in_course(:active_all => true, :course => @course2).user
        conversation = Conversation.initiate([u1.id, u2.id, u3.id], false)
        conversation.add_message(u1, 'test', :tags => [@course1.asset_string])
        cp = u2.conversations.first
        cp.tags.should eql [@course1.asset_string]

        conversation.add_message(u1, 'another', :tags => [@course2.asset_string])
        cp.reload.tags.sort.should eql [@course1.asset_string, @course2.asset_string].sort

        cp.remove_messages(cp.messages.human.first)
        cp.reload.tags.sort.should eql [@course1.asset_string, @course2.asset_string].sort
      end

      it "should add tags specified along with new recipients" do
        u1 = student_in_course(:active_all => true).user
        u2 = student_in_course(:active_all => true, :course => @course).user
        @course1 = @course
        @course2 = course(:active_all => true)
        @course2.enroll_student(u2).update_attribute(:workflow_state, 'active')
        u3 = student_in_course(:active_all => true, :course => @course2).user
        u4 = student_in_course(:active_all => true, :course => @course2).user
        conversation = Conversation.initiate([u1.id, u2.id, u3.id], false)
        conversation.add_message(u1, 'test', :tags => [@course1.asset_string])
        conversation.tags.should eql [@course1.asset_string]
        u1.conversations.first.tags.should eql [@course1.asset_string]
        u2.conversations.first.tags.should eql [@course1.asset_string]
        u3.conversations.first.tags.should eql [@course2.asset_string]

        conversation.add_participants(u2, [u4.id], :tags => [@course2.asset_string])
        conversation.reload.tags.sort.should eql [@course1.asset_string, @course2.asset_string].sort
        u1.conversations.first.tags.should eql [@course1.asset_string]
        u2.conversations.first.tags.sort.should eql [@course1.asset_string, @course2.asset_string].sort
        u3.conversations.first.tags.should eql [@course2.asset_string]
        u4.conversations.first.tags.should eql [@course2.asset_string]
      end
    end

    context "migration" do
      before do
        @u1 = student_in_course(:active_all => true).user
        @u2 = student_in_course(:active_all => true, :course => @course).user
        @course1 = @course
        @course2 = course(:active_all => true)
        @course2.enroll_student(@u2).update_attribute(:workflow_state, 'active')
        @u3 = student_in_course(:active_all => true, :course => @course2).user
        @conversation = Conversation.initiate([@u1.id, @u2.id, @u3.id], false)
        @conversation.add_message(@u1, 'test', :tags => [@course1.asset_string])
        Conversation.update_all "tags = NULL"
        ConversationParticipant.update_all "tags = NULL"
        ConversationMessageParticipant.update_all "tags = NULL"

        @conversation = Conversation.find(@conversation.id)
        @conversation.tags.should eql []
        @u1.conversations.first.tags.should eql []
        @u2.conversations.first.tags.should eql []
        @u3.conversations.first.tags.should eql []
      end

      it "should set the default tags when migrating" do
        @conversation.migrate_context_tags!

        @conversation.tags.sort.should eql [@course1.asset_string, @course2.asset_string].sort
        @u1.conversations.first.tags.should eql [@course1.asset_string]
        @u2.conversations.first.tags.sort.should eql [@course1.asset_string, @course2.asset_string].sort
        @u3.conversations.first.tags.should eql [@course2.asset_string]
      end

      it "should ignore conversation_participants without a user" do
        broken_one = @u3.conversations.first
        broken_one.user_id = nil
        broken_one.save!

        @conversation.migrate_context_tags!

        @conversation.tags.should eql [@course1.asset_string] # no course2 since participant is broken
        @u1.conversations.first.tags.should eql [@course1.asset_string]
        @u2.conversations.first.tags.should eql [@course1.asset_string]
        broken_one.reload.tags.should eql [] # skipped
      end
    end
  end

  context "root_account_ids" do
    it "should always be ordered" do
      conversation = Conversation.create
      conversation.update_attribute :root_account_ids, [3, 2, 1]
      conversation.root_account_ids.should eql [1, 2, 3]
    end

    it "should be saved on the conversation when adding a message" do
      u1 = user
      u2 = user
      conversation = Conversation.initiate([u1.id, u2.id], true)
      conversation.add_message(u1, 'ohai', :root_account_id => 1)
      conversation.add_message(u2, 'ohai yourself', :root_account_id => 2)
      conversation.root_account_ids.should eql [1, 2]
    end
  end
end
