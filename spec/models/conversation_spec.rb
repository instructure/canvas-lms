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

    it "should never change the workflow_state for the sender" do
      sender = user
      Conversation.initiate([sender.id, user.id], true).add_message(sender, 'test')
      convo = sender.conversations.first
      convo.update_attribute(:workflow_state, "unread")
      convo.add_message('another test')
      convo.reload.unread?.should be_true

      convo.update_attribute(:workflow_state, "archived")
      convo.add_message('one more test')
      convo.reload.archived?.should be_true

      convo.update_attribute(:workflow_state, "unread")
      convo.add_message('and another test', :update_for_sender => true) # overrides subscribed-ness and updates timestamps
      convo.reload.unread?.should be_true

      convo.update_attribute(:workflow_state, "archived")
      convo.add_message('last one', :update_for_sender => true)
      convo.reload.archived?.should be_true

      convo.remove_messages(:all)
      convo.add_message('for reals', :update_for_sender => true)
      convo.reload.archived?.should be_true
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
end