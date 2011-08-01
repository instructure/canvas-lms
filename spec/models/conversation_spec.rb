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
      convo.participants.size.should == 2 # doesn't include user, just the other people
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
    it "should increment when creating a conversation" do
      sender = user
      recipient = user
      root_convo = Conversation.initiate([sender.id, recipient.id], false)
      root_convo.add_message(sender, 'test')
      sender.reload.unread_conversations_count.should eql 0
      recipient.reload.unread_conversations_count.should eql 1
    end

    it "should increment for subscribed recipients when adding a message to a read conversation" do
      sender = user
      unread_guy = user
      subscribed_guy = user
      unsubscribed_guy = user
      root_convo = Conversation.initiate([sender.id, unread_guy.id, subscribed_guy.id, unsubscribed_guy.id], false)
      root_convo.add_message(sender, 'test')
      
      unread_guy.reload.unread_conversations_count.should eql 1
      subscribed_guy.conversations.first.mark_as_read
      subscribed_guy.reload.unread_conversations_count.should eql 0
      unsubscribed_guy.conversations.first.update_attributes(:subscribed => false)
      unsubscribed_guy.reload.unread_conversations_count.should eql 0

      root_convo.add_message(sender, 'test2')

      unread_guy.reload.unread_conversations_count.should eql 1
      subscribed_guy.reload.unread_conversations_count.should eql 1
      unsubscribed_guy.reload.unread_conversations_count.should eql 0
    end

    it "should decrement when deleting an unread conversation" do
      sender = user
      unread_guy = user
      root_convo = Conversation.initiate([sender.id, unread_guy.id], false)
      root_convo.add_message(sender, 'test')
      
      unread_guy.reload.unread_conversations_count.should eql 1
      unread_guy.conversations.first.remove_messages(:all)
      unread_guy.reload.unread_conversations_count.should eql 0
    end

    it "should decrement when marking as read" do
      sender = user
      unread_guy = user
      root_convo = Conversation.initiate([sender.id, unread_guy.id], false)
      root_convo.add_message(sender, 'test')
      
      unread_guy.reload.unread_conversations_count.should eql 1
      unread_guy.conversations.first.mark_as_read
      unread_guy.reload.unread_conversations_count.should eql 0
    end

    it "should indecrement when marking as unread" do
      sender = user
      unread_guy = user
      root_convo = Conversation.initiate([sender.id, unread_guy.id], false)
      root_convo.add_message(sender, 'test')
      unread_guy.conversations.first.mark_as_read
      
      unread_guy.reload.unread_conversations_count.should eql 0
      unread_guy.conversations.first.mark_as_unread
      unread_guy.reload.unread_conversations_count.should eql 1
    end
  end

  context "adding messages" do
    it "should deliver the message to all participants" do
      sender = user
      recipients = 5.times.map{ user }
      Conversation.initiate([sender.id] + recipients.map(&:id), false).add_message(sender, 'test')
      convo = sender.conversations.first
      convo.reload.read?.should be_true # but only for the sender
      convo.messages.size.should == 1
      convo.messages.first.body.should == 'test'
      recipients.each do |recipient|
        convo = recipient.conversations.first
        convo.read?.should be_false
        convo.messages.size.should == 1
        convo.messages.first.body.should == 'test'
      end
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
      convo.add_message('another test')

      rconvo.reload.unread?.should be_false
      rconvo.update_attributes(:subscribed => true)
      rconvo.unread?.should be_true
    end
  end
end