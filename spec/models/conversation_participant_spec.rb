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

describe ConversationParticipant do
  it "should correctly set up conversations" do
    sender = user
    recipient = user
    convo = sender.initiate_conversation([recipient])
    convo.add_message('test')

    sender.conversations.should == [convo]
    convo.participants.size.should == 2
    convo.conversation.participants.size.should == 2
    convo.messages.size.should == 1
  end

  it "should correctly manage messages" do
    sender = user
    recipient = user
    convo = sender.initiate_conversation([recipient])
    convo.add_message('test')
    convo.add_message('another')
    rconvo = recipient.conversations.first
    convo.messages.size.should == 2
    rconvo.messages.size.should == 2

    convo.remove_messages(convo.messages.last)
    convo.messages.reload
    convo.messages.size.should == 1
    convo.all_messages.size.should == 2
    # the recipient's messages are unaffected, since removing a message
    # only sets workflow state on the join table.
    rconvo.messages.size.should == 2

    convo.remove_messages(:all)
    convo.messages.size.should == 0
    convo.all_messages.size.should == 2
    rconvo.reload
    rconvo.messages.size.should == 2

    convo.delete_messages(:all)
    convo.all_messages.size.should == 0

    rconvo.delete_messages(rconvo.messages.last)
    rconvo.messages.size.should == 1
    rconvo.all_messages.size.should == 1
  end

  it "should update the updated_at stamp of its user on workflow_state change" do
    sender       = user
    recipient    = user
    updated_at   = sender.updated_at
    conversation = sender.initiate_conversation([recipient])
    conversation.update_attribute(:workflow_state, 'unread')
    sender.reload.updated_at.should_not eql updated_at
  end

  it "should support starred/starred=" do
    sender       = user
    recipient    = user
    conversation = sender.initiate_conversation([recipient])

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
    conversation = sender.initiate_conversation([recipient])

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
      c = @me.initiate_conversation(users)
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

    context "sharding" do
      specs_require_sharding

      it "should find conversations for users on different shards" do
        @shard1.activate do
          @u3 = user
          @c9 = conversation_for(@u3)
        end
        @me.conversations.tagged(@u3.asset_string).map(&:conversation).should == [@c9.conversation]
      end
    end
  end

  context "for_masquerading_user scope" do
    before do
      @a1 = Account.create
      @a2 = Account.create
      @a3 = Account.create
      @admin_user = user
      @a1.add_user(@admin_user)
      @a2.add_user(@admin_user)
      @a3.pseudonyms.create!(:user => @admin_user, :unique_id => 'a3') # in the account, but not an admin

      @target_user = user
      # visible to @user
      @c1 = @target_user.initiate_conversation([user])
      @c1.add_message("hey man", :root_account_id => @a1.id)
      @c2 = @target_user.initiate_conversation([user])
      @c2.add_message("foo", :root_account_id => @a1.id)
      @c2.add_message("bar", :root_account_id => @a2.id)
      # invisible to @user, unless @user is a site admin
      @c3 = @target_user.initiate_conversation([user])
      @c3.add_message("secret", :root_account_id => @a3.id)
      @c4 = @target_user.initiate_conversation([user])
      @c4.add_message("super", :root_account_id => @a1.id)
      @c4.add_message("sekrit", :root_account_id => @a3.id)
    end

    it "should let site admins see everything" do
      Account.site_admin.add_user(@admin_user)
      Account.site_admin.stubs(:grants_right?).with(@admin_user, :become_user).returns(false)
      convos = @target_user.conversations.for_masquerading_user(@admin_user)
      convos.size.should eql 4
      convos.should == @target_user.conversations.to_a
    end

    it "should limit others to their associated root accounts" do
      convos = @target_user.conversations.for_masquerading_user(@admin_user)
      convos.size.should eql 2
      convos.sort_by(&:id).should eql [@c1, @c2]
    end
  end

  context "participants" do
    before do
      @me = course_with_student(:active_all => true).user
      @u1 = student_in_course(:active_all => true).user
      @u2 = student_in_course(:active_all => true).user
      @u3 = student_in_course(:active_all => true).user
      @convo = @me.initiate_conversation([@u1, @u2, @u3])
      @convo.add_message "ohai"
      @u3.destroy
      @u4 = student_in_course(:active_all => true).user

      other_convo = @u4.initiate_conversation([@me])
      message = other_convo.add_message "just between you and me"
      @convo.add_message("haha i forwarded it", :forwarded_message_ids => [message.id])
    end

    it "should not include shared contexts by default" do
      users = @convo.reload.participants
      users.each do |user|
        user.common_groups.should be_empty
        user.common_courses.should be_empty
      end
    end

    it "should not include forwarded participants by default" do
      users = @convo.reload.participants
      users.map(&:id).sort.should eql [@me.id, @u1.id, @u2.id, @u3.id]
    end

    it "should include shared contexts if requested" do
      users = @convo.reload.participants(:include_participant_contexts => true)
      users.each do |user|
        user.common_groups.should == {}
        if [@me.id, @u3.id].include? user.id
          user.common_courses.should == {}
        else
          user.common_courses.should == {@course.id => ["StudentEnrollment"]}
        end
      end
    end

    it "should include include forwarded participants if requested" do
      users = @convo.reload.participants(:include_indirect_participants => true)
      users.map(&:id).sort.should eql [@me.id, @u1.id, @u2.id, @u3.id, @u4.id]
    end
  end

  context "move_to_user" do
    before do
      @user1 = user_model
      @user2 = user_model
    end

    it "should move a group conversation to the new user" do
      c = @user1.initiate_conversation([user, user])
      c.add_message("hello")
      c.update_attribute(:workflow_state, 'unread')

      c.move_to_user @user2

      c.reload.user_id.should eql @user2.id
      c.conversation.participants.map(&:id).should_not include(@user1.id)
      @user1.reload.unread_conversations_count.should eql 0
      @user2.reload.unread_conversations_count.should eql 1
    end

    it "should clean up group conversations having both users" do
      c = @user1.initiate_conversation([@user2, user, user])
      c.add_message("hello")
      c.update_attribute(:workflow_state, 'unread')
      rconvo = c.conversation
      rconvo.participants.size.should eql 4

      c.move_to_user @user2

      lambda{ c.reload }.should raise_error # deleted

      rconvo.reload
      rconvo.participants.size.should eql 3
      rconvo.participants.map(&:id).should_not include(@user1.id)
      rconvo.participants.map(&:id).should include(@user2.id)
      @user1.reload.unread_conversations_count.should eql 0
      @user2.reload.unread_conversations_count.should eql 1
    end

    it "should move a private conversation to the new user" do
      c = @user1.initiate_conversation([user])
      c.add_message("hello")
      c.update_attribute(:workflow_state, 'unread')
      rconvo = c.conversation
      old_hash = rconvo.private_hash

      c.reload.move_to_user @user2

      c.reload.user_id.should eql @user2.id
      rconvo.reload
      rconvo.participants.size.should eql 2
      rconvo.private_hash.should_not eql old_hash
      @user1.reload.unread_conversations_count.should eql 0
      @user2.reload.unread_conversations_count.should eql 1
    end

    it "should merge a private conversation into the existing private conversation" do
      other_guy = user
      c = @user1.initiate_conversation([other_guy])
      c.add_message("hello")
      c.update_attribute(:workflow_state, 'unread')
      c2 = @user2.initiate_conversation([other_guy])
      c2.add_message("hola")

      c.reload.move_to_user @user2

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
      c = @user1.initiate_conversation([@user2])
      c.add_message("hello self")
      c.update_attribute(:workflow_state, 'unread')
      @user2.mark_all_conversations_as_read!
      rconvo = c.conversation
      old_hash = rconvo.private_hash

      c.reload.move_to_user @user2

      lambda{ c.reload }.should raise_error # deleted
      rconvo.reload
      rconvo.participants.size.should eql 1
      rconvo.private_hash.should_not eql old_hash
      @user1.reload.unread_conversations_count.should eql 0
      @user2.reload.unread_conversations_count.should eql 1
    end

    it "should merge a private conversations between the two users into the existing monologue" do
      c = @user1.initiate_conversation([@user2])
      c.add_message("hello self")
      c.update_attribute(:workflow_state, 'unread')
      c2 = @user2.initiate_conversation([@user2])
      c2.add_message("monologue!")
      @user2.mark_all_conversations_as_read!

      c.reload.move_to_user @user2

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
      c = @user1.initiate_conversation([@user1])
      c.add_message("monologue 1")
      c.update_attribute(:workflow_state, 'unread')
      c2 = @user2.initiate_conversation([@user2])
      c2.add_message("monologue 2")

      c.reload.move_to_user @user2

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

    it "should not be adversely affected by an outer scope" do
      other_guy = user
      c = @user1.initiate_conversation([other_guy])
      c.add_message("hello")
      c.update_attribute(:workflow_state, 'unread')
      c2 = @user2.initiate_conversation([other_guy])
      c2.add_message("hola")

      c.reload
      ConversationParticipant.send :with_scope, :find => {:conditions => ["user_id = ?", @user1.id]} do
        c.move_to_user @user2
      end

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

    context "sharding" do
      specs_require_sharding

      it "should be able to move to a user on a different shard" do
        u1 = User.create!
        cp = u1.initiate_conversation([u1])
        @shard1.activate do
          u2 = User.create!
          cp.move_to_user(u2)
          cp.reload
          cp.user.should == u2
          cp2 = u2.all_conversations.first
          cp2.should_not == cp
          cp2.shard.should == @shard1
        end
      end
    end
  end
end
