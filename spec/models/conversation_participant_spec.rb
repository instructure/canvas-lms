# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe ConversationParticipant do
  it "sets up conversations correctly" do
    sender = user_factory
    recipient = user_factory
    convo = sender.initiate_conversation([recipient])
    convo.add_message("test")

    expect(sender.conversations).to eq [convo]
    expect(convo.participants.size).to eq 2
    expect(convo.conversation.participants.size).to eq 2
    expect(convo.messages.size).to eq 1
  end

  it "does not decrement unread_conversations_count to a negative number" do
    sender = user_factory
    recipient = user_factory
    convo = sender.initiate_conversation([recipient])
    convo.add_message("test")

    User.where(id: recipient).update_all(unread_conversations_count: 0) # force into the wrong state

    part = recipient.conversations.first
    part.update_one(event: "mark_as_read")

    recipient.reload
    expect(recipient.unread_conversations_count).to eq 0
  end

  it "manages messages correctly" do
    sender = user_factory
    recipient = user_factory
    convo = sender.initiate_conversation([recipient])
    convo.add_message("test")
    convo.add_message("another")
    rconvo = recipient.conversations.first
    expect(convo.messages.size).to eq 2
    expect(rconvo.messages.size).to eq 2

    convo.remove_messages(convo.messages.last)
    convo.messages.reload
    expect(convo.messages.size).to eq 1
    expect(convo.all_messages.size).to eq 2
    # the recipient's messages are unaffected, since removing a message
    # only sets workflow state on the join table.
    expect(rconvo.messages.size).to eq 2

    convo.remove_messages(:all)
    expect(convo.messages.size).to eq 0
    expect(convo.all_messages.size).to eq 2
    rconvo.reload
    expect(rconvo.messages.size).to eq 2

    convo.delete_messages(:all)
    expect(convo.all_messages.size).to eq 0

    rconvo.delete_messages(rconvo.messages.last)
    expect(rconvo.messages.size).to eq 1
    expect(rconvo.all_messages.size).to eq 1
  end

  it "updates the updated_at stamp of its user on workflow_state change" do
    sender       = user_factory
    recipient    = user_factory
    updated_at   = sender.updated_at
    conversation = sender.initiate_conversation([recipient])
    conversation.update_attribute(:workflow_state, "unread")
    expect(sender.reload.updated_at).not_to eql updated_at
  end

  it "supports starred/starred=" do
    sender       = user_factory
    recipient    = user_factory
    conversation = sender.initiate_conversation([recipient])

    conversation.starred = true
    conversation.save
    conversation.reload
    expect(conversation.starred).to be_truthy

    conversation.starred = false
    conversation.save
    conversation.reload
    expect(conversation.starred).to be_falsey
  end

  it "supports :starred in update" do
    sender       = user_factory
    recipient    = user_factory
    conversation = sender.initiate_conversation([recipient])

    conversation.update(starred: true)
    conversation.save
    conversation.reload
    expect(conversation.starred).to be_truthy

    conversation.update(starred: false)
    conversation.save
    conversation.reload
    expect(conversation.starred).to be_falsey
  end

  context "tagged scope" do
    def conversation_for(*tags_or_users)
      users, tags = tags_or_users.partition { |u| u.is_a?(User) }
      users << user_factory if users.empty?
      c = @me.initiate_conversation(users)
      c.add_message("test")
      c.tags = tags
      c.save!
      c.reload
    end

    before :once do
      @me = user_factory
      @c1 = conversation_for("course_1")
      @c2 = conversation_for("course_1", "course_2")
      @c3 = conversation_for("course_2")
      @c4 = conversation_for("group_1")
      @c5 = conversation_for(@u1 = user_factory)
      @c6 = conversation_for(@u2 = user_factory)
      @c7 = conversation_for(@u1, @u2)
      @c8 = conversation_for("course_1", @u1, user_factory)
    end

    it "returns conversations that match the given course" do
      expect(@me.conversations.tagged("course_1").sort_by(&:id)).to eql [@c1, @c2, @c8]
    end

    it "returns conversations that match any of the given courses" do
      expect(@me.conversations.tagged("course_1", "course_2").sort_by(&:id)).to eql [@c1, @c2, @c3, @c8]
    end

    it "returns conversations that match all of the given courses" do
      expect(@me.conversations.tagged("course_1", "course_2", mode: :and).sort_by(&:id)).to eql [@c2]
    end

    it "returns conversations that match the given group" do
      expect(@me.conversations.tagged("group_1").sort_by(&:id)).to eql [@c4]
    end

    it "returns conversations that match the given user" do
      expect(@me.conversations.tagged(@u1.asset_string).sort_by(&:id)).to eql [@c5, @c7, @c8]
    end

    it "returns conversations that match any of the given users" do
      expect(@me.conversations.tagged(@u1.asset_string, @u2.asset_string).sort_by(&:id)).to eql [@c5, @c6, @c7, @c8]
    end

    it "returns conversations that match all of the given users" do
      expect(@me.conversations.tagged(@u1.asset_string, @u2.asset_string, mode: :and).sort_by(&:id)).to eql [@c7]
    end

    it "returns conversations that match either the given course or user" do
      expect(@me.conversations.tagged(@u1.asset_string, "course_1").sort_by(&:id)).to eql [@c1, @c2, @c5, @c7, @c8]
    end

    it "returns conversations that match both the given course and user" do
      expect(@me.conversations.tagged(@u1.asset_string, "course_1", mode: :and).sort_by(&:id)).to eql [@c8]
    end

    context "sharding" do
      specs_require_sharding

      it "finds conversations for users on different shards" do
        @shard1.activate do
          @u3 = user_factory
          @c9 = conversation_for(@u3)
        end
        expect(@me.conversations.tagged(@u3.asset_string).map(&:conversation)).to eq [@c9.conversation]
      end
    end
  end

  context "for_masquerading_user scope" do
    before :once do
      @a1 = Account.create
      @a2 = Account.create
      @a3 = Account.create
      @admin_user = user_factory
      @a1.account_users.create!(user: @admin_user)
      @a2.account_users.create!(user: @admin_user)
      @a3.pseudonyms.create!(user: @admin_user, unique_id: "a3") # in the account, but not an admin

      @target_user = user_factory
      # visible to @user
      @c1 = @target_user.initiate_conversation([user_factory])
      @c1.add_message("hey man", root_account_id: @a1.id)
      @c2 = @target_user.initiate_conversation([user_factory])
      @c2.add_message("foo", root_account_id: @a1.id)
      @c2.add_message("bar", root_account_id: @a2.id)
      # invisible to @user, unless @user is a site admin
      @c3 = @target_user.initiate_conversation([user_factory])
      @c3.add_message("secret", root_account_id: @a3.id)
      @c4 = @target_user.initiate_conversation([user_factory])
      @c4.add_message("super", root_account_id: @a1.id)
      @c4.add_message("sekrit", root_account_id: @a3.id)
    end

    it "lets site admins see everything" do
      Account.site_admin.account_users.create!(user: @admin_user)
      allow(Account.site_admin).to receive(:grants_right?).with(@admin_user, :become_user).and_return(false)
      convos = @target_user.conversations.for_masquerading_user(@admin_user, @target_user)
      expect(convos.size).to be 4
      expect(convos).to eq @target_user.conversations.to_a
    end

    it "limits others to their associated root accounts" do
      convos = @target_user.conversations.for_masquerading_user(@admin_user, @target_user)
      expect(convos.size).to be 2
      expect(convos.sort_by(&:id)).to eql [@c1, @c2]
    end
  end

  context "participants" do
    before :once do
      @me = course_with_student(active_all: true).user
      @u1 = student_in_course(active_all: true).user
      @u2 = student_in_course(active_all: true).user
      @u3 = student_in_course(active_all: true).user
      @convo = @me.initiate_conversation([@u1, @u2, @u3])
      @convo.add_message "ohai"
      @u3.destroy
      @u4 = student_in_course(active_all: true).user

      other_convo = @u4.initiate_conversation([@me])
      message = other_convo.add_message "just between you and me"
      @convo.add_message("haha i forwarded it", forwarded_message_ids: [message.id])
    end

    matcher :have_same_ids do |expected|
      match do |actual|
        actual.map(&:id).sort == expected.map(&:id).sort
      end
    end

    it "does not include shared contexts by default" do
      users = @convo.reload.participants
      users.each do |user|
        next if user == @me

        expect(@me.address_book.cached?(user)).to be_falsey
      end
    end

    it "does not include forwarded participants by default" do
      users = @convo.reload.participants
      expect(users).to have_same_ids [@me, @u1, @u2, @u3]
    end

    it "includes shared contexts if requested" do
      users = @convo.reload.participants(include_participant_contexts: true)
      address_book = @me.address_book
      users.each do |user|
        expect(address_book.cached?(user)).to be_truthy
        common_groups = address_book.common_groups(user)
        common_courses = address_book.common_courses(user)
        expect(common_groups).to eq({})
        if [@me.id, @u3.id].include? user.id
          expect(common_courses).to eq({})
        else
          expect(common_courses).to eq({ @course.id => ["StudentEnrollment"] })
        end
      end
    end

    it "includes include forwarded participants if requested" do
      users = @convo.reload.participants(include_indirect_participants: true)
      expect(users).to have_same_ids [@me, @u1, @u2, @u3, @u4]
    end

    it "caches participants per conversation" do
      allow(Rails.cache).to receive(:fetch) do |key, &block|
        expect(key).to eq([@convo.conversation, "participants"].cache_key)
        expect(block.call).to have_same_ids([@me, @u1, @u2, @u3])
      end
      @convo.participants
    end

    it "caches indirect participants per conversation and user" do
      expect(Rails.cache).to receive(:fetch).with([@convo.conversation, @convo.user, "indirect_participants"].cache_key)
      allow(Rails.cache).to receive(:fetch) do |key, &block; users|
        users = block.call
        if key == [@convo.conversation, @convo.user, "indirect_participants"].cache_key
          expect(users).to have_same_ids([@u4])
        end
        users
      end
      @convo.participants(include_indirect_participants: true)
    end
  end

  context "move_to_user" do
    before :once do
      @user1 = user_model
      @user2 = user_model
    end

    it "moves a group conversation to the new user" do
      enable_cache do
        c = @user1.initiate_conversation([user_factory, user_factory])
        c.add_message("hello")
        c.update_attribute(:workflow_state, "unread")

        # populates the cache
        expect(c.participants.map(&:id)).to include(@user1.id)

        c.move_to_user @user2

        expect(c.reload.user_id).to eql @user2.id
        expect(c.participants.map(&:id)).not_to include(@user1.id)
        expect(@user1.reload.unread_conversations_count).to be 0
        expect(@user2.reload.unread_conversations_count).to be 1
      end
    end

    it "cleans up group conversations having both users" do
      c = @user1.initiate_conversation([@user2, user_factory, user_factory])
      c.add_message("hello")
      c.update_attribute(:workflow_state, "unread")
      rconvo = c.conversation
      expect(rconvo.participants.size).to be 4

      c.move_to_user @user2

      expect { c.reload }.to raise_error(ActiveRecord::RecordNotFound) # deleted

      rconvo.reload
      expect(rconvo.participants.size).to be 3
      expect(rconvo.participants.map(&:id)).not_to include(@user1.id)
      expect(rconvo.participants.map(&:id)).to include(@user2.id)
      expect(@user1.reload.unread_conversations_count).to be 0
      expect(@user2.reload.unread_conversations_count).to be 1
    end

    it "moves a private conversation to the new user" do
      c = @user1.initiate_conversation([user_factory])
      c.add_message("hello")
      c.update_attribute(:workflow_state, "unread")
      rconvo = c.conversation
      old_hash = rconvo.private_hash

      c.reload.move_to_user @user2

      expect(c.reload.user_id).to eql @user2.id
      rconvo.reload
      expect(rconvo.participants.size).to be 2
      expect(rconvo.private_hash).not_to eql old_hash
      expect(@user1.reload.unread_conversations_count).to be 0
      expect(@user2.reload.unread_conversations_count).to be 1
    end

    it "merges a private conversation into the existing private conversation" do
      other_guy = user_factory
      c = @user1.initiate_conversation([other_guy])
      c.add_message("hello")
      c.update_attribute(:workflow_state, "unread")
      c2 = @user2.initiate_conversation([other_guy])
      c2.add_message("hola")

      c.reload.move_to_user @user2

      expect { c.reload }.to raise_error(ActiveRecord::RecordNotFound) # deleted
      expect { Conversation.find(c.conversation_id) }.to raise_error(ActiveRecord::RecordNotFound) # deleted

      expect(c2.reload.messages.size).to be 2
      expect(c2.messages.map(&:author_id)).to eql [@user2.id, @user2.id]
      expect(c2.message_count).to be 2
      expect(c2.user_id).to eql @user2.id
      expect(c2.conversation.participants.size).to be 2
      expect(@user1.reload.unread_conversations_count).to be 0
      expect(@user2.reload.unread_conversations_count).to be 1
      expect(other_guy.reload.unread_conversations_count).to be 1
    end

    it "changes a private conversation between the two users into a monologue" do
      c = @user1.initiate_conversation([@user2])
      c.add_message("hello self")
      c.update_attribute(:workflow_state, "unread")
      @user2.mark_all_conversations_as_read!
      rconvo = c.conversation
      old_hash = rconvo.private_hash

      c.reload.move_to_user @user2

      expect { c.reload }.to raise_error(ActiveRecord::RecordNotFound) # deleted
      rconvo.reload
      expect(rconvo.participants.size).to be 1
      expect(rconvo.private_hash).not_to eql old_hash
      expect(@user1.reload.unread_conversations_count).to be 0
      expect(@user2.reload.unread_conversations_count).to be 1
    end

    it "merges a private conversations between the two users into the existing monologue" do
      c = @user1.initiate_conversation([@user2])
      c.add_message("hello self")
      c.update_attribute(:workflow_state, "unread")
      c2 = @user2.initiate_conversation([@user2])
      c2.add_message("monologue!")
      @user2.mark_all_conversations_as_read!

      c.reload.move_to_user @user2

      expect { c.reload }.to raise_error(ActiveRecord::RecordNotFound) # deleted
      expect { Conversation.find(c.conversation_id) }.to raise_error(ActiveRecord::RecordNotFound) # deleted

      expect(c2.reload.messages.size).to be 2
      expect(c2.messages.map(&:author_id)).to eql [@user2.id, @user2.id]
      expect(c2.message_count).to be 2
      expect(c2.user_id).to eql @user2.id
      expect(c2.conversation.participants.size).to be 1
      expect(@user1.reload.unread_conversations_count).to be 0
      expect(@user2.reload.unread_conversations_count).to be 1
    end

    it "merges a monologue into the existing monologue" do
      c = @user1.initiate_conversation([@user1])
      c.add_message("monologue 1")
      c.update_attribute(:workflow_state, "unread")
      c2 = @user2.initiate_conversation([@user2])
      c2.add_message("monologue 2")

      c.reload.move_to_user @user2

      expect { c.reload }.to raise_error(ActiveRecord::RecordNotFound) # deleted
      expect { Conversation.find(c.conversation_id) }.to raise_error(ActiveRecord::RecordNotFound) # deleted

      expect(c2.reload.messages.size).to be 2
      expect(c2.messages.map(&:author_id)).to eql [@user2.id, @user2.id]
      expect(c2.message_count).to be 2
      expect(c2.user_id).to eql @user2.id
      expect(c2.conversation.participants.size).to be 1
      expect(@user1.reload.unread_conversations_count).to be 0
      expect(@user2.reload.unread_conversations_count).to be 1
    end

    it "is not adversely affected by an outer scope" do
      other_guy = user_factory
      c = @user1.initiate_conversation([other_guy])
      c.add_message("hello")
      c.update_attribute(:workflow_state, "unread")
      c2 = @user2.initiate_conversation([other_guy])
      c2.add_message("hola")

      c.reload
      ConversationParticipant.where(user_id: @user1.id).scoping do
        c.move_to_user @user2
      end

      expect { c.reload }.to raise_error(ActiveRecord::RecordNotFound) # deleted
      expect { Conversation.find(c.conversation_id) }.to raise_error(ActiveRecord::RecordNotFound) # deleted

      expect(c2.reload.messages.size).to be 2
      expect(c2.messages.map(&:author_id)).to eql [@user2.id, @user2.id]
      expect(c2.message_count).to be 2
      expect(c2.user_id).to eql @user2.id
      expect(c2.conversation.participants.size).to be 2
      expect(@user1.reload.unread_conversations_count).to be 0
      expect(@user2.reload.unread_conversations_count).to be 1
      expect(other_guy.reload.unread_conversations_count).to be 1
    end

    context "sharding" do
      specs_require_sharding

      it "is able to move to a user on a different shard" do
        u1 = User.create!
        cp = u1.initiate_conversation([u1])
        @shard1.activate do
          u2 = User.create!
          cp.move_to_user(u2)
          cp.reload
          expect(cp.user).to eq u2
          cp2 = u2.all_conversations.first
          expect(cp2).not_to eq cp
          expect(cp2.shard).to eq @shard1
        end
      end

      describe "for_masquerading_user scope" do
        it "finds participants with global ids in root_account_ids" do
          @a1 = Account.create
          @admin_user = user_factory
          @a1.account_users.create!(user: @admin_user)
          @target_user = user_factory
          @c1 = @target_user.initiate_conversation([user_factory])
          @c1.add_message("foo", root_account_id: @a1.id)

          # not sure how this happens in prod, but it does
          @c1.update_attribute(:root_account_ids, [@a1.id, @a1.global_id].sort.join(","))

          convos = @target_user.conversations.for_masquerading_user(@admin_user, @target_user)
          expect(convos.size).to be 1
          expect(convos.sort_by(&:id)).to eql [@c1]

          @cross_shard_admin = @shard1.activate { user_factory }
          @a1.account_users.create!(user: @cross_shard_admin)
          convos = @target_user.conversations.for_masquerading_user(@cross_shard_admin, @target_user)
          expect(convos.size).to be 1
        end
      end
    end
  end
end
