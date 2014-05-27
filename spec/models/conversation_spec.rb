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

require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper.rb')

describe Conversation do
  context "initiation" do
    it "should set private_hash for private conversations" do
      users = 2.times.map{ user }
      Conversation.initiate(users, true).private_hash.should_not be_nil
    end

    it "should not set private_hash for group conversations" do
      users = 3.times.map{ user }
      Conversation.initiate(users, false).private_hash.should be_nil
    end

    it "should reuse private conversations" do
      users = 2.times.map{ user }
      c1 = Conversation.initiate(users, true)
      c2 = Conversation.initiate(users, true)
      c1.should == c2
      ActiveRecord::Base
    end

    it "should not reuse group conversations" do
      users = 2.times.map{ user }
      Conversation.initiate(users, false).should_not ==
      Conversation.initiate(users, false)
    end

    it "should populate subject if provided" do
      users = 2.times.map{ user }
      Conversation.initiate(users, nil, :subject => 'lunch').subject.should == 'lunch'
    end

    context "sharding" do
      specs_require_sharding

      it "should create the conversation on the appropriate shard" do
        users = []
        users << user(:name => 'a')
        @shard1.activate { users << user(:name => 'b') }
        @shard2.activate { users << user(:name => 'c') }
        Shard.with_each_shard([Shard.default, @shard1, @shard2]) do
          conversation = Conversation.initiate(users, false)
          conversation.shard.should == Shard.current
          conversation.conversation_participants.all? { |cp| cp.shard == Shard.current }.should be_true
          conversation.conversation_participants.length.should == 3
          conversation.participants.map(&:id).should == users.map(&:id)
          cp = users[0].all_conversations.last
          cp.shard.should == Shard.default
          cp = users[1].all_conversations.last
          cp.shard.should == @shard1
          cp = users[2].all_conversations.last
          cp.shard.should == @shard2
        end
      end

      it "should re-use a private conversation from any shard" do
        users = [user]
        @shard1.activate { users << user }
        conversation = Conversation.initiate(users, true)
        Conversation.initiate(users, true).should == conversation
        @shard1.activate do
          Conversation.initiate(users, true).should == conversation
        end
        @shard2.activate do
          Conversation.initiate(users, true).should == conversation
        end
      end

      it "should re-use a private conversation from an unrelated shard" do
        users = []
        @shard1.activate { users << user }
        @shard2.activate { users << user }
        conversation = Conversation.initiate(users, true)
        Conversation.initiate(users, true).should == conversation
        @shard1.activate do
          Conversation.initiate(users, true).should == conversation
        end
        @shard2.activate do
          Conversation.initiate(users, true).should == conversation
        end
      end
    end
  end

  context "adding participants" do
    it "should not add participants to private conversations" do
      sender = user
      root_convo = Conversation.initiate([sender, user], true)
      lambda{ root_convo.add_participants(sender, [user]) }.should raise_error
    end

    it "should add new participants to group conversations and give them all messages" do
      sender = user
      root_convo = Conversation.initiate([sender, user], false)
      root_convo.add_message(sender, 'test')

      new_guy = user
      lambda{ root_convo.add_participants(sender, [new_guy]) }.should_not raise_error
      root_convo.participants(true).size.should == 3

      convo = new_guy.conversations.first
      convo.unread?.should be_true
      convo.messages.size.should == 2 # the test message plus a "user was added" message
      convo.participants.size.should == 3 # includes the sender (though we don't show him in the ui)
    end

    it "should only add participants to messages the existing user has participants on" do
      sender = user
      recipient = user
      root_convo = Conversation.initiate([sender, recipient], false)
      msgs = []
      msgs << root_convo.add_message(sender, "first message body")  <<
              root_convo.add_message(sender, "second message body") <<
              root_convo.add_message(sender, "third message body")  <<
              root_convo.add_message(sender, "fourth message body")
      sender.conversations.first.remove_messages(msgs[0])
      sender.conversations.first.delete_messages(msgs[1])

      new_guy = user
      root_convo.add_participants(sender, [new_guy])
      # -1 for hard delete msg, +1 for generated message. soft deleted should still be added.
      new_guy.conversations.first.messages.size.should eql(msgs.size - 1 + 1)
    end


    it "should not re-add existing participants to group conversations" do
      sender = user
      recipient = user
      root_convo = Conversation.initiate([sender, recipient], false)
      lambda{ root_convo.add_participants(sender, [recipient]) }.should_not raise_error
      root_convo.participants.size.should == 2
    end

    it "should update the updated_at timestamp and clear the identity header cache of new participants" do
      sender = user
      root_convo = Conversation.initiate([sender, user], false)
      root_convo.add_message(sender, 'test')

      new_guy = user
      old_updated_at = new_guy.updated_at
      root_convo.add_participants(sender, [new_guy])
      new_guy.reload.updated_at.should_not eql old_updated_at
    end

    context "sharding" do
      specs_require_sharding

      it "should add participants to the proper shards" do
        users = []
        users << user(:name => 'a')
        users << user(:name => 'b')
        users << user(:name => 'c')
        conversation = Conversation.initiate(users, false)
        conversation.add_message(users.first, 'test')
        conversation.conversation_participants.size.should == 3
        @shard1.activate do
          users << user(:name => 'd')
          conversation.add_participants(users.first, [users.last])
          conversation.conversation_participants(:reload).size.should == 4
          conversation.conversation_participants.all? { |cp| cp.shard == Shard.default }.should be_true
          users.last.all_conversations.last.shard.should == @shard1
          conversation.participants(true).map(&:id).should == users.map(&:id)
        end
        @shard2.activate do
          users << user(:name => 'e')
          conversation.add_participants(users.first, users[-2..-1])
          conversation.conversation_participants(:reload).size.should == 5
          conversation.conversation_participants.all? { |cp| cp.shard == Shard.default }.should be_true
          users.last.all_conversations.last.shard.should == @shard2
          conversation.participants(true).map(&:id).should == users.map(&:id)
        end
      end
    end
  end

  context "message counts" do
    shared_examples_for "message counts" do
      before do
        (@shard1 || Shard.default).activate do
          @sender = user
          @recipient = user
        end
      end
      it "should increment when adding messages" do
        Conversation.initiate([@sender, @recipient], false).add_message(@sender, 'test')
        @sender.conversations.first.message_count.should eql 1
        @recipient.conversations.first.message_count.should eql 1
      end

      it "should decrement when removing messages" do
        root_convo = Conversation.initiate([@sender, @recipient], false)
        root_convo.add_message(@sender, 'test')
        msg = root_convo.add_message(@sender, 'test2')
        @sender.conversations.first.message_count.should eql 2
        @recipient.conversations.first.message_count.should eql 2

        @sender.conversations.first.remove_messages(msg)
        @sender.conversations.first.reload.message_count.should eql 1
        @recipient.conversations.first.reload.message_count.should eql 2
      end

      it "should decrement when deleting messages" do
        root_convo = Conversation.initiate([@sender, @recipient], false)
        root_convo.add_message(@sender, 'test')
        msg = root_convo.add_message(@sender, 'test2')
        @sender.conversations.first.message_count.should eql 2
        @recipient.conversations.first.message_count.should eql 2

        @sender.conversations.first.delete_messages(msg)
        @sender.conversations.first.reload.message_count.should eql 1
        @recipient.conversations.first.reload.message_count.should eql 2
      end
    end

    include_examples "message counts"

    context "sharding" do
      specs_require_sharding
      include_examples "message counts"
    end
  end

  context "unread counts" do
    shared_examples_for "unread counts" do
      before do
        (@shard1 || Shard.default).activate do
          @sender = user
          @unread_guy = @recipient = user
          @subscribed_guy = user
          @unsubscribed_guy = user
        end
      end

      it "should increment for recipients when sending the first message in a conversation" do
        root_convo = Conversation.initiate([@sender, @recipient], false)
        ConversationParticipant.unread.size.should eql 0 # only once the first message is added
        root_convo.add_message(@sender, 'test')
        @sender.reload.unread_conversations_count.should eql 0
        @sender.conversations.unread.size.should eql 0
        @recipient.reload.unread_conversations_count.should eql 1
        @recipient.conversations.unread.size.should eql 1
      end

      it "should increment for subscribed recipients when adding a message to a read conversation" do
        root_convo = Conversation.initiate([@sender, @unread_guy, @subscribed_guy, @unsubscribed_guy], false)
        root_convo.add_message(@sender, 'test')

        @unread_guy.reload.unread_conversations_count.should eql 1
        @unread_guy.conversations.unread.size.should eql 1
        @subscribed_guy.conversations.first.update_attribute(:workflow_state, "read")
        @subscribed_guy.reload.unread_conversations_count.should eql 0
        @subscribed_guy.conversations.unread.size.should eql 0
        @unsubscribed_guy.conversations.first.update_attributes(:subscribed => false)
        @unsubscribed_guy.reload.unread_conversations_count.should eql 0
        @unsubscribed_guy.conversations.unread.size.should eql 0

        root_convo.add_message(@sender, 'test2')

        @unread_guy.reload.unread_conversations_count.should eql 1
        @unread_guy.conversations.unread.size.should eql 1
        @subscribed_guy.reload.unread_conversations_count.should eql 1
        @subscribed_guy.conversations.unread.size.should eql 1
        @unsubscribed_guy.reload.unread_conversations_count.should eql 0
        @unsubscribed_guy.conversations.unread.size.should eql 0
      end

      it "should decrement when deleting an unread conversation" do
        root_convo = Conversation.initiate([@sender, @unread_guy], false)
        root_convo.add_message(@sender, 'test')

        @unread_guy.reload.unread_conversations_count.should eql 1
        @unread_guy.conversations.unread.size.should eql 1
        @unread_guy.conversations.first.remove_messages(:all)
        @unread_guy.reload.unread_conversations_count.should eql 0
        @unread_guy.conversations.unread.size.should eql 0
      end

      it "should decrement when marking as read" do
        root_convo = Conversation.initiate([@sender, @unread_guy], false)
        root_convo.add_message(@sender, 'test')

        @unread_guy.reload.unread_conversations_count.should eql 1
        @unread_guy.conversations.unread.size.should eql 1
        @unread_guy.conversations.first.update_attribute(:workflow_state, "read")
        @unread_guy.reload.unread_conversations_count.should eql 0
        @unread_guy.conversations.unread.size.should eql 0
      end

      it "should indecrement when marking as unread" do
        root_convo = Conversation.initiate([@sender, @unread_guy], false)
        root_convo.add_message(@sender, 'test')
        @unread_guy.conversations.first.update_attribute(:workflow_state, "read")

        @unread_guy.reload.unread_conversations_count.should eql 0
        @unread_guy.conversations.unread.size.should eql 0
        @unread_guy.conversations.first.update_attribute(:workflow_state, "unread")
        @unread_guy.reload.unread_conversations_count.should eql 1
        @unread_guy.conversations.unread.size.should eql 1
      end
    end

    include_examples "unread counts"
    context "sharding" do
      specs_require_sharding
      include_examples "unread counts"
    end
  end

  context "subscription" do
    it "should mark-as-read when unsubscribing iff it was unread" do
      sender = user
      subscription_guy = user
      archive_guy = user
      root_convo = Conversation.initiate([sender, archive_guy, subscription_guy], false)
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
      root_convo = Conversation.initiate([sender, flip_flopper_guy, archive_guy, subscription_guy], false)
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
      subscription_guy.conversations.first.last_message_at.to_i.should eql last_message_at.to_i

      archive_guy.reload.unread_conversations_count.should eql 1
      archive_guy.conversations.unread.size.should eql 1
      subscription_guy.conversations.first.last_message_at.to_i.should eql last_message_at.to_i
    end

    it "should not toggle read/unread until the subscription change is saved" do
      sender = user
      subscription_guy = user
      root_convo = Conversation.initiate([sender, user, subscription_guy], false)
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
      Conversation.initiate([sender] + recipients, false).add_message(sender, 'test')
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
      Conversation.initiate([sender, user], true).add_message(sender, 'test')
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
      rconvo = Conversation.initiate([sender, user], true)
      message = rconvo.add_message(sender, 'test')
      convo = sender.conversations.first
      convo.last_message_at.should_not be_nil

      convo.remove_messages(message)
      convo.last_message_at.should be_nil

      convo.add_message('bulk message', :update_for_sender => false)
      convo.reload
      convo.last_message_at.should be_nil
    end

    it "should set last_authored_at and visible_last_authored_at on deleted conversations even if update_for_sender=false" do
      expected_times = [Time.now.utc - 1.hours, Time.now.utc].map{ |t| Time.parse(t.to_s) }
      ConversationMessage.any_instance.expects(:current_time_from_proper_timezone).twice.returns(*expected_times)

      sender = user
      rconvo = Conversation.initiate([sender, user], true)
      message = rconvo.add_message(sender, 'test')
      convo = sender.conversations.first
      convo.last_authored_at.should eql expected_times.first
      convo.visible_last_authored_at.should eql expected_times.first

      convo.remove_messages(message)
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
      Conversation.initiate([sender] + recipients, false).add_message(sender, 'test')

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

        conversation = Conversation.initiate([u1, u2], true)

        conversation.current_context_strings(1).should eql [course1.asset_string]
        u1.conversation_context_codes.sort.should eql [course1.asset_string, course2.asset_string].sort # just once
      end
    end

    context "initial tags" do
      it "should save all valid tags on the conversation" do # NOTE: this will change if/when we allow arbitrary tags
        u1 = student_in_course(:active_all => true).user
        u2 = student_in_course(:active_all => true, :course => @course).user
        conversation = Conversation.initiate([u1, u2], true)
        conversation.add_message(u1, 'test', :tags => [@course.asset_string, "asdf", "lol"])
        conversation.tags.should eql [@course.asset_string]
      end

      it "should set initial empty tags on the conversation and conversation_participant" do
        u1 = student_in_course.user
        u2 = student_in_course(:course => @course).user
        conversation = Conversation.initiate([u1, u2], true)
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
        conversation = Conversation.initiate([u1, u2, u3], false)
        conversation.add_message(u1, 'test', :tags => [@course1.asset_string, @course2.asset_string])
        conversation.tags.should eql [@course1.asset_string]
      end

      it "should save all visible tags on the conversation_participant" do
        u1 = student_in_course(:active_all => true).user
        u2 = student_in_course(:active_all => true, :course => @course).user
        u3 = user
        conversation = Conversation.initiate([u1, u2, u3], false)
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
        conversation = Conversation.initiate([u1, u2, u3], false)
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
        conversation = Conversation.initiate([u1, u2, u3], false)
        conversation.add_message(u1, 'test', :tags => [@course1.asset_string])
        conversation.tags.should eql [@course1.asset_string]
        u1.conversations.first.tags.should eql [@course1.asset_string]
        u2.conversations.first.tags.should eql [@course1.asset_string] # just the one, since it was explicit
        u3.conversations.first.tags.should eql [@course2.asset_string] # not in course1, so fall back to common ones (i.e. course2)
      end

      context "sharding" do
        specs_require_sharding

        it "should set all tags on the other shard's participants" do
          course1 = @shard1.activate{ course(:account => Account.create!, :active_all => true) }
          course2 = @shard2.activate{ course(:account => Account.create!, :active_all => true) }
          user1 = student_in_course(:course => course1, :active_all => true).user
          user2 = student_in_course(:course => course2, :active_all => true).user
          student_in_course(:course => course2, :user => user1, :active_all => true)
          student_in_course(:course => course1, :user => user2, :active_all => true)
          conversation = Conversation.initiate([user1, user2], false)
          conversation.add_message(user1, 'test')
          user1.conversations.first.tags.sort.should eql [course1.asset_string, course2.asset_string].sort
          user2.conversations.first.tags.sort.should eql [course1.asset_string, course2.asset_string].sort
        end
      end
    end

    context "deletion" do
      it "should remove tags when all messages are deleted" do
        u1 = student_in_course(:active_all => true).user
        u2 = student_in_course(:active_all => true, :course => @course).user
        conversation = Conversation.initiate([u1, u2], true)
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
        conversation = Conversation.initiate([u1, u2, u3], false)
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
        conversation = Conversation.initiate([u1, u2, u3], false)
        conversation.add_message(u1, 'test', :tags => [@course1.asset_string])
        u1.conversations.first.tags.should == [@course1.asset_string]
        u2.conversations.first.tags.should == [@course1.asset_string]
        u3.conversations.first.tags.should == [@course2.asset_string]

        conversation.add_message(u1, 'another', :tags => [@course2.asset_string, "course_0"])
        u1.conversations.first.tags.should == [@course1.asset_string]
        u2.conversations.first.tags.sort.should == [@course1.asset_string, @course2.asset_string].sort
        u3.conversations.first.tags.should == [@course2.asset_string]
      end

      it "should ignore conversation_participants without a valid user" do
        u1 = student_in_course(:active_all => true).user
        u2 = student_in_course(:active_all => true, :course => @course).user
        @course1 = @course
        @course2 = course(:active_all => true)
        @course2.enroll_student(u2).update_attribute(:workflow_state, 'active')
        u3 = student_in_course(:active_all => true, :course => @course2).user
        conversation = Conversation.initiate([u1, u2, u3], false)
        conversation.add_message(u1, 'test', :tags => [@course1.asset_string])
        u1.conversations.first.tags.should == [@course1.asset_string]
        u2.conversations.first.tags.should == [@course1.asset_string]
        u3.conversations.first.tags.should == [@course2.asset_string]
        broken_one = u3.conversations.first
        ConversationParticipant.where(id: broken_one).update_all(user_id: -1, tags: '')

        conversation.reload
        conversation.add_message(u1, 'another', :tags => [@course2.asset_string, "course_0"])
        u1.conversations.first.tags.should == [@course1.asset_string]
        u2.conversations.first.tags.sort.should == [@course1.asset_string]
        broken_one.reload.tags.should == []
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
        conversation = Conversation.initiate([u1, u2], true)
        conversation.add_message(u1, 'test', :tags => [@course1.asset_string])
        cp = u2.conversations.first
        cp.messages.human.first.tags.should eql [@course1.asset_string]

        conversation.add_message(u1, 'another', :tags => [@course2.asset_string, "course_0"])
        cp.messages.human.first.tags.should eql [@course2.asset_string]
      end

      it "should save the previous message tags on the conversation_message_participant if there are no new visible ones" do
        u1 = student_in_course(:active_all => true).user
        u2 = student_in_course(:active_all => true, :course => @course).user
        conversation = Conversation.initiate([u1, u2], true)
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
        conversation = Conversation.initiate([u1, u2], true)
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
        conversation = Conversation.initiate([u1, u2, u3], false)
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
        conversation = Conversation.initiate([u1, u2, u3], false)
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
        conversation = Conversation.initiate([u1, u2, u3], false)
        conversation.add_message(u1, 'test', :tags => [@course1.asset_string])
        conversation.tags.should eql [@course1.asset_string]
        u1.conversations.first.tags.should eql [@course1.asset_string]
        u2.conversations.first.tags.should eql [@course1.asset_string]
        u3.conversations.first.tags.should eql [@course2.asset_string]

        conversation.add_participants(u2, [u4], :tags => [@course2.asset_string])
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
        @conversation = Conversation.initiate([@u1, @u2, @u3], false)
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
        ConversationParticipant.where(id: broken_one).update_all(user_id: -1)

        @conversation.migrate_context_tags!

        @conversation.tags.should eql [@course1.asset_string] # no course2 since participant is broken
        @u1.conversations.first.tags.should eql [@course1.asset_string]
        @u2.conversations.first.tags.should eql [@course1.asset_string]
        broken_one.reload.tags.should eql [] # skipped
      end
    end

    context 'tag updates' do
      before(:each) do
        @teacher    = teacher_in_course(:active_all => true).user
        @student    = student_in_course(:active_all => true, :course => @course).user
        @old_course = @course
      end

      it "should remove old tags and add new ones" do
        conversation = Conversation.initiate([@teacher, @student], true)
        conversation.add_message(@teacher, 'first message')

        new_course = course
        new_course.offer!
        new_course.enroll_teacher(@teacher).accept!
        new_course.enroll_student(@student).accept!

        @old_course.complete!

        third_course = course
        third_course.offer!
        third_course.enroll_teacher(@teacher).accept!

        conversation.reload
        conversation.add_message(@student, 'second message')

        conversation.conversation_participants.each do |participant|
          participant.reload
          participant.tags.should == [new_course.asset_string]
        end
      end

      it "should continue to use old tags if there are no current shared contexts" do
        conversation = Conversation.initiate([@teacher, @student], true)
        conversation.add_message(@teacher, 'first message')

        @old_course.complete!

        teacher_course = course
        teacher_course.offer!
        teacher_course.enroll_teacher(@teacher).accept!

        student_course = course
        student_course.offer!
        student_course.enroll_student(@student).accept!

        conversation.add_message(@student, 'second message')

        conversation.conversation_participants.each do |participant|
          participant.reload
          participant.tags.should == [@old_course.asset_string]
        end
      end

      it "should use concluded tags from multiple courses" do
        old_course2 = course

        old_course2.offer!
        old_course2.enroll_teacher(@teacher).accept!
        old_course2.enroll_student(@student).accept!

        conversation = Conversation.initiate([@teacher, @student], true)
        conversation.add_message(@teacher, 'first message')

        [@old_course, old_course2].each { |c| c.complete! }

        teacher_course = course
        teacher_course.offer!
        teacher_course.enroll_teacher(@teacher).accept!

        student_course = course
        student_course.offer!
        student_course.enroll_student(@student).accept!

        conversation.add_message(@teacher, 'second message')

        conversation.conversation_participants.each do |participant|
          participant.reload
          participant.tags.sort.should == [@old_course, old_course2].map(&:asset_string).sort
        end
      end

      it "should include concluded group contexts when no active ones exist" do
        student1 = student_in_course(:active_all => true, :course => @old_course).user
        student2 = student_in_course(:active_all => true, :course => @old_course).user

        group      = Group.create!(:context => @old_course)
        [student1, student2].each { |s| group.users << s }

        conversation = Conversation.initiate([student1, student2], true)
        conversation.add_message(student1, 'first message')

        @old_course.complete!
        group.complete!

        conversation.add_message(student2, 'second message')

        conversation.conversation_participants.each do |participant|
          participant.reload
          participant.tags.should include(group.asset_string)
        end
      end

      it "should replace concluded group contexts with active ones" do
        student1 = student_in_course(:active_all => true, :course => @old_course).user
        student2 = student_in_course(:active_all => true, :course => @old_course).user

        old_group = Group.create!(:context => @old_course)
        [student1, student2].each { |s| old_group.users << s }

        conversation = Conversation.initiate([student1, student2], true)
        conversation.add_message(student1, 'first message')

        @old_course.complete!
        old_group.destroy

        new_course = course
        new_course.offer!
        [student1, student2].each { |s| new_course.enroll_student(s).accept! }
        new_group = Group.create!(:context => new_course)
        new_group.users << student1
        new_group.users << student2

        conversation.reload
        conversation.add_message(student2, 'second message')

        conversation.conversation_participants.each do |participant|
          participant.reload
          participant.tags.sort.should == [new_group, new_course].map(&:asset_string).sort
        end
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
      conversation = Conversation.initiate([u1, u2], true)
      conversation.add_message(u1, 'ohai', :root_account_id => 1)
      conversation.add_message(u2, 'ohai yourself', :root_account_id => 2)
      conversation.root_account_ids.should eql [1, 2]
    end
  end

  def merge_and_check(sender, source, target, source_user, target_user)
    raise "source_user and target_user must be the same" if source_user && target_user && source_user != target_user
    source.add_participants(sender, [source_user]) if source_user
    target.add_participants(sender, [target_user]) if target_user
    target_user = source_user || target_user
    message_count = source.shard.activate { ConversationMessageParticipant.joins(:conversation_message).where(:user_id => target_user, :conversation_messages => {:conversation_id => source}).count }
    message_count += target.shard.activate { ConversationMessageParticipant.joins(:conversation_message).where(:user_id => target_user, :conversation_messages => {:conversation_id => target}).count }

    source.merge_into(target)

    lambda { source.reload }.should raise_error(ActiveRecord::RecordNotFound)
    ConversationParticipant.find_all_by_conversation_id(source.id).should == []
    ConversationMessage.find_all_by_conversation_id(source.id).should == []

    target.reload
    target.participants(true).map(&:id).should == [sender.id, target_user.id]
    target_user.reload.all_conversations.map(&:conversation).should == [target]
    cp = target_user.all_conversations.first
    cp.messages.length.should == message_count
  end

  describe "merge_into" do
    # non-sharding cases are covered by ConversationParticipant#move_to_user specs

    context "sharding" do
      specs_require_sharding

      before do
        @sender = User.create!(:name => 'a')
        @conversation1 = Conversation.initiate([@sender], false)
        @conversation2 = Conversation.initiate([@sender], false)
        @conversation3 = @shard1.activate { Conversation.initiate([@sender], false) }
        @user1 = User.create!(:name => 'b')
        @user2 = @shard1.activate { User.create!(:name => 'c') }
        @user3 = @shard2.activate { User.create!(:name => 'd') }
        @conversation1.add_message(@sender, 'message1')
        @conversation2.add_message(@sender, 'message2')
        @conversation3.add_message(@sender, 'message3')
      end

      context "matching shards" do
        it "user from another shard participating in both conversations" do
          merge_and_check(@sender, @conversation1, @conversation2, @user2, @user2)
          @conversation2.associated_shards.sort_by(&:id).should == [Shard.default, @shard1].sort_by(&:id)
        end

        it "user from another shard participating in source conversation only" do
          merge_and_check(@sender, @conversation1, @conversation2, @user2, nil)
          @conversation2.associated_shards.sort_by(&:id).should == [Shard.default, @shard1].sort_by(&:id)
        end
      end

      context "differing shards" do
        it "user from source shard participating in both conversations" do
          merge_and_check(@sender, @conversation1, @conversation3, @user1, @user1)
          @conversation3.associated_shards.sort_by(&:id).should == [@shard1, Shard.default].sort_by(&:id)
        end

        it "user from destination shard participating in both conversations" do
          merge_and_check(@sender, @conversation1, @conversation3, @user2, @user2)
          @conversation3.associated_shards.sort_by(&:id).should == [@shard1, Shard.default].sort_by(&:id)
        end

        it "user from third shard participating in both conversations" do
          merge_and_check(@sender, @conversation1, @conversation3, @user3, @user3)
          @conversation3.associated_shards.sort_by(&:id).should == [Shard.default, @shard1, @shard2].sort_by(&:id)
        end

        it "user from source shard participating in source conversation only" do
          merge_and_check(@sender, @conversation1, @conversation3, @user1, nil)
          @conversation3.associated_shards.sort_by(&:id).should == [@shard1, Shard.default].sort_by(&:id)
        end

        it "user from destination shard participating in source conversation only" do
          merge_and_check(@sender, @conversation1, @conversation3, @user2, nil)
          @conversation3.associated_shards.sort_by(&:id).should == [@shard1, Shard.default].sort_by(&:id)
        end

        it "user from third shard participating in source conversation only" do
          merge_and_check(@sender, @conversation1, @conversation3, @user3, nil)
          @conversation3.associated_shards.sort_by(&:id).should == [Shard.default, @shard1, @shard2].sort_by(&:id)
        end
      end
    end
  end
end
