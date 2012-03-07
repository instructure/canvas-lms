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

describe ConversationParticipant do
  it "should correctly set up conversations" do
    sender = user
    recipient = user
    convo = sender.initiate_conversation([recipient.id])
    convo.add_message('test')

    sender.conversations.should == [convo]
    convo.participants.size.should == 2
    convo.conversation.participants.size.should == 2
    convo.messages.size.should == 1
  end

  it "should correctly manage messages" do
    sender = user
    recipient = user
    convo = sender.initiate_conversation([recipient.id])
    convo.add_message('test')
    convo.add_message('another')
    rconvo = recipient.conversations.first
    convo.messages.size.should == 2
    rconvo.messages.size.should == 2

    convo.messages.delete(convo.messages.last)
    convo.messages.reload
    convo.messages.size.should == 1
    # the recipient's messages are unaffected, since it's a has_many :through
    rconvo.messages.size.should == 2

    convo.messages.clear
    rconvo.reload
    rconvo.messages.size.should == 2
  end

  it "should update the updated_at stamp of its user on workflow_state change" do
    sender       = user
    recipient    = user
    updated_at   = sender.updated_at
    conversation = sender.initiate_conversation([recipient.id])
    conversation.update_attribute(:workflow_state, 'unread')
    sender.reload.updated_at.should_not eql updated_at
  end

  it "should support starred/starred=" do
    sender       = user
    recipient    = user
    conversation = sender.initiate_conversation([recipient.id])

    conversation.starred = true
    conversation.save
    conversation.reload
    conversation.starred.should be_true

    conversation.starred = false
    conversation.save
    conversation.reload
    conversation.starred.should be_false
  end

  it "should support :starred in update_attributes" do
    sender       = user
    recipient    = user
    conversation = sender.initiate_conversation([recipient.id])

    conversation.update_attributes(:starred => true)
    conversation.save
    conversation.reload
    conversation.starred.should be_true

    conversation.update_attributes(:starred => false)
    conversation.save
    conversation.reload
    conversation.starred.should be_false
  end

  context "tagged scope" do
    def conversation_for(*tags_or_users)
      users, tags = tags_or_users.partition{ |u| u.is_a?(User) }
      users << user if users.empty?
      c = @me.initiate_conversation(users.map(&:id))
      c.add_message("test")
      c.tags = tags
      c.save!
      c.reload
    end

    before do
      @me = user
      @c1 = conversation_for("course_1")
      @c2 = conversation_for("course_1", "course_2")
      @c3 = conversation_for("course_2")
      @c4 = conversation_for("group_1")
      @c5 = conversation_for(@u1 = user)
      @c6 = conversation_for(@u2 = user)
      @c7 = conversation_for(@u1, @u2)
      @c8 = conversation_for("course_1", @u1, user)
    end

    it "should return conversations that match the given course" do
      @me.conversations.tagged("course_1").sort_by(&:id).should eql [@c1, @c2, @c8]
    end

    it "should return conversations that match any of the given courses" do
      @me.conversations.tagged("course_1", "course_2").sort_by(&:id).should eql [@c1, @c2, @c3, @c8]
    end

    it "should return conversations that match all of the given courses" do
      @me.conversations.tagged("course_1", "course_2", :mode => :and).sort_by(&:id).should eql [@c2]
    end

    it "should return conversations that match the given group" do
      @me.conversations.tagged("group_1").sort_by(&:id).should eql [@c4]
    end

    it "should return conversations that match the given user" do
      @me.conversations.tagged(@u1.asset_string).sort_by(&:id).should eql [@c5, @c7, @c8]
    end

    it "should return conversations that match any of the given users" do
      @me.conversations.tagged(@u1.asset_string, @u2.asset_string).sort_by(&:id).should eql [@c5, @c6, @c7, @c8]
    end

    it "should return conversations that match all of the given users" do
      @me.conversations.tagged(@u1.asset_string, @u2.asset_string, :mode => :and).sort_by(&:id).should eql [@c7]
    end

    it "should return conversations that match either the given course or user" do
      @me.conversations.tagged(@u1.asset_string, "course_1").sort_by(&:id).should eql [@c1, @c2, @c5, @c7, @c8]
    end

    it "should return conversations that match both the given course and user" do
      @me.conversations.tagged(@u1.asset_string, "course_1", :mode => :and).sort_by(&:id).should eql [@c8]
    end
  end

  context "move_to_user" do
    before do
      @user1 = user_model
      @user2 = user_model
    end

    it "should move a group conversation to the new user" do
      c = @user1.initiate_conversation([user.id, user.id])
      c.add_message("hello")
      c.update_attribute(:workflow_state, 'unread')

      c.move_to_user @user2

      c.reload.user_id.should eql @user2.id
      c.conversation.participant_ids.should_not include(@user1.id)
      @user1.reload.unread_conversations_count.should eql 0
      @user2.reload.unread_conversations_count.should eql 1
    end

    it "should clean up group conversations having both users" do
      c = @user1.initiate_conversation([@user2.id, user.id, user.id])
      c.add_message("hello")
      c.update_attribute(:workflow_state, 'unread')
      rconvo = c.conversation
      rconvo.participant_ids.size.should eql 4

      c.move_to_user @user2

      lambda{ c.reload }.should raise_error # deleted

      rconvo.reload
      rconvo.participants.size.should eql 3
      rconvo.participant_ids.should_not include(@user1.id)
      rconvo.participant_ids.should include(@user2.id)
      @user1.reload.unread_conversations_count.should eql 0
      @user2.reload.unread_conversations_count.should eql 1
    end

    it "should move a private conversation to the new user" do
      c = @user1.initiate_conversation([user.id])
      c.add_message("hello")
      c.update_attribute(:workflow_state, 'unread')
      rconvo = c.conversation
      old_hash = rconvo.private_hash

      c.move_to_user @user2

      c.reload.user_id.should eql @user2.id
      rconvo.reload
      rconvo.participants.size.should eql 2
      rconvo.private_hash.should_not eql old_hash
      @user1.reload.unread_conversations_count.should eql 0
      @user2.reload.unread_conversations_count.should eql 1
    end

    it "should merge a private conversation into the existing private conversation" do
      other_guy = user
      c = @user1.initiate_conversation([other_guy.id])
      c.add_message("hello")
      c.update_attribute(:workflow_state, 'unread')
      c2 = @user2.initiate_conversation([other_guy.id])
      c2.add_message("hola")

      c.move_to_user @user2

      lambda{ c.reload }.should raise_error # deleted
      lambda{ Conversation.find(c.conversation_id) }.should raise_error # deleted

      c2.reload.messages.size.should eql 2
      c2.messages.map(&:author_id).should eql [@user2.id, @user2.id]
      c2.message_count.should eql 2
      c2.user_id.should eql @user2.id
      c2.conversation.participants.size.should eql 2
      @user1.reload.unread_conversations_count.should eql 0
      @user2.reload.unread_conversations_count.should eql 1
      other_guy.reload.unread_conversations_count.should eql 1
    end

    it "should change a private conversation between the two users into a monologue" do
      c = @user1.initiate_conversation([@user2.id])
      c.add_message("hello self")
      c.update_attribute(:workflow_state, 'unread')
      @user2.mark_all_conversations_as_read!
      rconvo = c.conversation
      old_hash = rconvo.private_hash

      c.move_to_user @user2

      lambda{ c.reload }.should raise_error # deleted
      rconvo.reload
      rconvo.participants.size.should eql 1
      rconvo.private_hash.should_not eql old_hash
      @user1.reload.unread_conversations_count.should eql 0
      @user2.reload.unread_conversations_count.should eql 1
    end

    it "should merge a private conversations between the two users into the existing monologue" do
      c = @user1.initiate_conversation([@user2.id])
      c.add_message("hello self")
      c.update_attribute(:workflow_state, 'unread')
      c2 = @user2.initiate_conversation([@user2.id])
      c2.add_message("monologue!")
      @user2.mark_all_conversations_as_read!

      c.move_to_user @user2

      lambda{ c.reload }.should raise_error # deleted
      lambda{ Conversation.find(c.conversation_id) }.should raise_error # deleted

      c2.reload.messages.size.should eql 2
      c2.messages.map(&:author_id).should eql [@user2.id, @user2.id]
      c2.message_count.should eql 2
      c2.user_id.should eql @user2.id
      c2.conversation.participants.size.should eql 1
      @user1.reload.unread_conversations_count.should eql 0
      @user2.reload.unread_conversations_count.should eql 1
    end

    it "should merge a monologue into the existing monologue" do
      c = @user1.initiate_conversation([@user1.id])
      c.add_message("monologue 1")
      c.update_attribute(:workflow_state, 'unread')
      c2 = @user2.initiate_conversation([@user2.id])
      c2.add_message("monologue 2")

      c.move_to_user @user2

      lambda{ c.reload }.should raise_error # deleted
      lambda{ Conversation.find(c.conversation_id) }.should raise_error # deleted

      c2.reload.messages.size.should eql 2
      c2.messages.map(&:author_id).should eql [@user2.id, @user2.id]
      c2.message_count.should eql 2
      c2.user_id.should eql @user2.id
      c2.conversation.participants.size.should eql 1
      @user1.reload.unread_conversations_count.should eql 0
      @user2.reload.unread_conversations_count.should eql 1
    end
  end
end
