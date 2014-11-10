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
  let_once(:sender) { user }
  let_once(:recipient) { user }

  context "initiation" do
    it "should set private_hash for private conversations" do
      users = create_users(2, return_type: :record)
      expect(Conversation.initiate(users, true).private_hash).not_to be_nil
    end

    it "should not set private_hash for group conversations" do
      users = create_users(3, return_type: :record)
      expect(Conversation.initiate(users, false).private_hash).to be_nil
    end

    it "should reuse private conversations" do
      users = create_users(2, return_type: :record)
      c1 = Conversation.initiate(users, true)
      c2 = Conversation.initiate(users, true)
      expect(c1).to eq c2
      ActiveRecord::Base
    end

    it "should not reuse group conversations" do
      users = create_users(2, return_type: :record)
      expect(Conversation.initiate(users, false)).not_to eq(
      Conversation.initiate(users, false)
      )
    end

    it "should populate subject if provided" do
      users = create_users(2, return_type: :record)
      expect(Conversation.initiate(users, nil, :subject => 'lunch').subject).to eq 'lunch'
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
          expect(conversation.shard).to eq Shard.current
          expect(conversation.conversation_participants.all? { |cp| cp.shard == Shard.current }).to be_truthy
          expect(conversation.conversation_participants.length).to eq 3
          expect(conversation.participants.map(&:id)).to eq users.map(&:id)
          cp = users[0].all_conversations.last
          expect(cp.shard).to eq Shard.default
          cp = users[1].all_conversations.last
          expect(cp.shard).to eq @shard1
          cp = users[2].all_conversations.last
          expect(cp.shard).to eq @shard2
        end
      end

      it "should re-use a private conversation from any shard" do
        users = [user]
        @shard1.activate { users << user }
        conversation = Conversation.initiate(users, true)
        expect(Conversation.initiate(users, true)).to eq conversation
        @shard1.activate do
          expect(Conversation.initiate(users, true)).to eq conversation
        end
        @shard2.activate do
          expect(Conversation.initiate(users, true)).to eq conversation
        end
      end

      it "should re-use a private conversation from an unrelated shard" do
        users = []
        @shard1.activate { users << user }
        @shard2.activate { users << user }
        conversation = Conversation.initiate(users, true)
        expect(Conversation.initiate(users, true)).to eq conversation
        @shard1.activate do
          expect(Conversation.initiate(users, true)).to eq conversation
        end
        @shard2.activate do
          expect(Conversation.initiate(users, true)).to eq conversation
        end
      end
    end
  end

  context "adding participants" do
    it "should not add participants to private conversations" do
      root_convo = Conversation.initiate([sender, recipient], true)
      expect{ root_convo.add_participants(sender, [user]) }.to raise_error
    end

    it "should add new participants to group conversations and give them all messages" do
      root_convo = Conversation.initiate([sender, recipient], false)
      root_convo.add_message(sender, 'test')

      new_guy = user
      expect{ root_convo.add_participants(sender, [new_guy]) }.not_to raise_error
      expect(root_convo.participants(true).size).to eq 3

      convo = new_guy.conversations.first
      expect(convo.unread?).to be_truthy
      expect(convo.messages.size).to eq 2 # the test message plus a "user was added" message
      expect(convo.participants.size).to eq 3 # includes the sender (though we don't show him in the ui)
    end

    it "should only add participants to messages the existing user has participants on" do
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
      expect(new_guy.conversations.first.messages.size).to eql(msgs.size - 1 + 1)
    end


    it "should not re-add existing participants to group conversations" do
      root_convo = Conversation.initiate([sender, recipient], false)
      expect{ root_convo.add_participants(sender, [recipient]) }.not_to raise_error
      expect(root_convo.participants.size).to eq 2
    end

    it "should update the updated_at timestamp and clear the identity header cache of new participants" do
      root_convo = Conversation.initiate([sender, recipient], false)
      root_convo.add_message(sender, 'test')

      new_guy = user
      old_updated_at = new_guy.updated_at
      root_convo.add_participants(sender, [new_guy])
      expect(new_guy.reload.updated_at).not_to eql old_updated_at
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
        expect(conversation.conversation_participants.size).to eq 3
        @shard1.activate do
          users << user(:name => 'd')
          conversation.add_participants(users.first, [users.last])
          expect(conversation.conversation_participants(:reload).size).to eq 4
          expect(conversation.conversation_participants.all? { |cp| cp.shard == Shard.default }).to be_truthy
          expect(users.last.all_conversations.last.shard).to eq @shard1
          expect(conversation.participants(true).map(&:id)).to eq users.map(&:id)
        end
        @shard2.activate do
          users << user(:name => 'e')
          conversation.add_participants(users.first, users[-2..-1])
          expect(conversation.conversation_participants(:reload).size).to eq 5
          expect(conversation.conversation_participants.all? { |cp| cp.shard == Shard.default }).to be_truthy
          expect(users.last.all_conversations.last.shard).to eq @shard2
          expect(conversation.participants(true).map(&:id)).to eq users.map(&:id)
        end
      end
    end
  end

  context "message counts" do
    shared_examples_for "message counts" do
      before :once do
        (@shard1 || Shard.default).activate do
          @sender = user
          @recipient = user
        end
      end
      it "should increment when adding messages" do
        Conversation.initiate([@sender, @recipient], false).add_message(@sender, 'test')
        expect(@sender.conversations.first.message_count).to eql 1
        expect(@recipient.conversations.first.message_count).to eql 1
      end

      it "should decrement when removing messages" do
        root_convo = Conversation.initiate([@sender, @recipient], false)
        root_convo.add_message(@sender, 'test')
        msg = root_convo.add_message(@sender, 'test2')
        expect(@sender.conversations.first.message_count).to eql 2
        expect(@recipient.conversations.first.message_count).to eql 2

        @sender.conversations.first.remove_messages(msg)
        expect(@sender.conversations.first.reload.message_count).to eql 1
        expect(@recipient.conversations.first.reload.message_count).to eql 2
      end

      it "should decrement when deleting messages" do
        root_convo = Conversation.initiate([@sender, @recipient], false)
        root_convo.add_message(@sender, 'test')
        msg = root_convo.add_message(@sender, 'test2')
        expect(@sender.conversations.first.message_count).to eql 2
        expect(@recipient.conversations.first.message_count).to eql 2

        @sender.conversations.first.delete_messages(msg)
        expect(@sender.conversations.first.reload.message_count).to eql 1
        expect(@recipient.conversations.first.reload.message_count).to eql 2
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
      before :once do
        (@shard1 || Shard.default).activate do
          @sender = user
          @unread_guy = @recipient = user
          @subscribed_guy = user
          @unsubscribed_guy = user
        end
      end

      it "should increment for recipients when sending the first message in a conversation" do
        root_convo = Conversation.initiate([@sender, @recipient], false)
        expect(ConversationParticipant.unread.size).to eql 0 # only once the first message is added
        root_convo.add_message(@sender, 'test')
        expect(@sender.reload.unread_conversations_count).to eql 0
        expect(@sender.conversations.unread.size).to eql 0
        expect(@recipient.reload.unread_conversations_count).to eql 1
        expect(@recipient.conversations.unread.size).to eql 1
      end

      it "should increment for subscribed recipients when adding a message to a read conversation" do
        root_convo = Conversation.initiate([@sender, @unread_guy, @subscribed_guy, @unsubscribed_guy], false)
        root_convo.add_message(@sender, 'test')

        expect(@unread_guy.reload.unread_conversations_count).to eql 1
        expect(@unread_guy.conversations.unread.size).to eql 1
        @subscribed_guy.conversations.first.update_attribute(:workflow_state, "read")
        expect(@subscribed_guy.reload.unread_conversations_count).to eql 0
        expect(@subscribed_guy.conversations.unread.size).to eql 0
        @unsubscribed_guy.conversations.first.update_attributes(:subscribed => false)
        expect(@unsubscribed_guy.reload.unread_conversations_count).to eql 0
        expect(@unsubscribed_guy.conversations.unread.size).to eql 0

        root_convo.add_message(@sender, 'test2')

        expect(@unread_guy.reload.unread_conversations_count).to eql 1
        expect(@unread_guy.conversations.unread.size).to eql 1
        expect(@subscribed_guy.reload.unread_conversations_count).to eql 1
        expect(@subscribed_guy.conversations.unread.size).to eql 1
        expect(@unsubscribed_guy.reload.unread_conversations_count).to eql 0
        expect(@unsubscribed_guy.conversations.unread.size).to eql 0
      end

      it "should increment only for message participants" do
        root_convo = Conversation.initiate([@sender, @recipient, @subscribed_guy], false)
        root_convo.add_message(@sender, 'test')

        @subscribed_guy.conversations.first.update_attribute(:workflow_state, "read")
        expect(@subscribed_guy.reload.unread_conversations_count).to eql 0
        expect(@subscribed_guy.conversations.unread.size).to eql 0

        root_convo.add_message(@sender, 'test2', :only_users => [@recipient])

        expect(@subscribed_guy.reload.unread_conversations_count).to eql 0
        expect(@subscribed_guy.conversations.unread.size).to eql 0
      end

      it "should decrement when deleting an unread conversation" do
        root_convo = Conversation.initiate([@sender, @unread_guy], false)
        root_convo.add_message(@sender, 'test')

        expect(@unread_guy.reload.unread_conversations_count).to eql 1
        expect(@unread_guy.conversations.unread.size).to eql 1
        @unread_guy.conversations.first.remove_messages(:all)
        expect(@unread_guy.reload.unread_conversations_count).to eql 0
        expect(@unread_guy.conversations.unread.size).to eql 0
      end

      it "should decrement when marking as read" do
        root_convo = Conversation.initiate([@sender, @unread_guy], false)
        root_convo.add_message(@sender, 'test')

        expect(@unread_guy.reload.unread_conversations_count).to eql 1
        expect(@unread_guy.conversations.unread.size).to eql 1
        @unread_guy.conversations.first.update_attribute(:workflow_state, "read")
        expect(@unread_guy.reload.unread_conversations_count).to eql 0
        expect(@unread_guy.conversations.unread.size).to eql 0
      end

      it "should indecrement when marking as unread" do
        root_convo = Conversation.initiate([@sender, @unread_guy], false)
        root_convo.add_message(@sender, 'test')
        @unread_guy.conversations.first.update_attribute(:workflow_state, "read")

        expect(@unread_guy.reload.unread_conversations_count).to eql 0
        expect(@unread_guy.conversations.unread.size).to eql 0
        @unread_guy.conversations.first.update_attribute(:workflow_state, "unread")
        expect(@unread_guy.reload.unread_conversations_count).to eql 1
        expect(@unread_guy.conversations.unread.size).to eql 1
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
      subscription_guy = user
      archive_guy = user
      root_convo = Conversation.initiate([sender, archive_guy, subscription_guy], false)
      root_convo.add_message(sender, 'test')

      expect(subscription_guy.reload.unread_conversations_count).to eql 1
      expect(subscription_guy.conversations.unread.size).to eql 1

      subscription_guy.conversations.first.update_attributes(:subscribed => false)
      expect(subscription_guy.reload.unread_conversations_count).to eql 0
      expect(subscription_guy.conversations.unread.size).to eql 0

      archive_guy.conversations.first.update_attributes(:workflow_state => "archived", :subscribed => false)
      expect(archive_guy.conversations.archived.size).to eql 1
    end

    it "should mark-as-unread when re-subscribing iff there are newer messages" do
      flip_flopper_guy = user
      subscription_guy = user
      archive_guy = user
      root_convo = Conversation.initiate([sender, flip_flopper_guy, archive_guy, subscription_guy], false)
      root_convo.add_message(sender, 'test')

      flip_flopper_guy.conversations.first.update_attributes(:subscribed => false)
      expect(flip_flopper_guy.reload.unread_conversations_count).to eql 0
      expect(flip_flopper_guy.conversations.unread.size).to eql 0
      # no new messages in the interim, he should stay "marked-as-read"
      flip_flopper_guy.conversations.first.update_attributes(:subscribed => true)
      expect(flip_flopper_guy.reload.unread_conversations_count).to eql 0
      expect(flip_flopper_guy.conversations.unread.size).to eql 0

      subscription_guy.conversations.first.update_attributes(:subscribed => false)
      archive_guy.conversations.first.update_attributes(:workflow_state => "archived", :subscribed => false)

      message = root_convo.add_message(sender, 'you wish you were subscribed!')
      message.update_attribute(:created_at, Time.now.utc + 1.minute)
      last_message_at = message.reload.created_at

      subscription_guy.conversations.first.update_attributes(:subscribed => true)
      archive_guy.conversations.first.update_attributes(:subscribed => true)

      expect(subscription_guy.reload.unread_conversations_count).to eql 1
      expect(subscription_guy.conversations.unread.size).to eql 1
      expect(subscription_guy.conversations.first.last_message_at.to_i).to eql last_message_at.to_i

      expect(archive_guy.reload.unread_conversations_count).to eql 1
      expect(archive_guy.conversations.unread.size).to eql 1
      expect(subscription_guy.conversations.first.last_message_at.to_i).to eql last_message_at.to_i
    end

    it "should not toggle read/unread until the subscription change is saved" do
      subscription_guy = user
      root_convo = Conversation.initiate([sender, user, subscription_guy], false)
      root_convo.add_message(sender, 'test')

      expect(subscription_guy.reload.unread_conversations_count).to eql 1
      expect(subscription_guy.conversations.unread.size).to eql 1

      subscription_guy.conversations.first.subscribed = false
      expect(subscription_guy.reload.unread_conversations_count).to eql 1
      expect(subscription_guy.conversations.unread.size).to eql 1

      subscription_guy.conversations.first.subscribed = true
      expect(subscription_guy.reload.unread_conversations_count).to eql 1
      expect(subscription_guy.conversations.unread.size).to eql 1
    end
  end

  context "adding messages" do
    it "should deliver the message to all participants" do
      recipients = create_users(5, return_type: :record)
      Conversation.initiate([sender] + recipients, false).add_message(sender, 'test')
      convo = sender.conversations.first
      expect(convo.reload.read?).to be_truthy # only for the sender, and then only on the first message
      expect(convo.messages.size).to eq 1
      expect(convo.messages.first.body).to eq 'test'
      recipients.each do |recipient|
        convo = recipient.conversations.first
        expect(convo.read?).to be_falsey
        expect(convo.messages.size).to eq 1
        expect(convo.messages.first.body).to eq 'test'
      end
    end

    it "should broadcast conversation created" do

      n2 = Notification.create(:name => "Conversation Created", :category => "TestImmediately")

      [sender].each do |user|
        channel = user.communication_channels.create(:path => "test_channel_email_#{user.id}", :path_type => "email")
        channel.confirm

        NotificationPolicy.create(:notification => n2, :communication_channel => channel, :frequency => "immediately")
      end

      recipients = create_users(5, return_type: :record)
      conversation = Conversation.initiate(recipients, false).add_message(sender, 'test', :cc_author => true);

      # check that our sender recieved a conversation created notification
      expect(conversation.messages_sent).to include("Conversation Created")
    end

    it "should only ever change the workflow_state for the sender if it's archived and it's a direct message (not bulk)" do
      Conversation.initiate([sender, recipient], true).add_message(sender, 'test')
      convo = sender.conversations.first
      convo.update_attribute(:workflow_state, "unread")
      convo.add_message('another test', :update_for_sender => false) # as if it were a bulk private message
      expect(convo.reload.unread?).to be_truthy

      convo.update_attribute(:workflow_state, "archived")
      convo.add_message('one more test', :update_for_sender => false)
      expect(convo.reload.archived?).to be_truthy

      convo.update_attribute(:workflow_state, "unread")
      convo.add_message('and another test') # overrides subscribed-ness and updates timestamps
      expect(convo.reload.unread?).to be_truthy

      convo.update_attribute(:workflow_state, "archived")
      convo.add_message('last one')
      expect(convo.reload.archived?).to be_falsey
      expect(convo.reload.read?).to be_truthy
    end

    it "should not set last_message_at for the sender if the conversation is deleted and update_for_sender=false" do
      rconvo = Conversation.initiate([sender, recipient], true)
      message = rconvo.add_message(sender, 'test')
      convo = sender.conversations.first
      expect(convo.last_message_at).not_to be_nil

      convo.remove_messages(message)
      expect(convo.last_message_at).to be_nil

      convo.add_message('bulk message', :update_for_sender => false)
      convo.reload
      expect(convo.last_message_at).to be_nil
    end

    it "should set last_authored_at and visible_last_authored_at on deleted conversations even if update_for_sender=false" do
      expected_times = [Time.now.utc - 1.hours, Time.now.utc].map{ |t| Time.parse(t.to_s) }
      ConversationMessage.any_instance.expects(:current_time_from_proper_timezone).twice.returns(*expected_times)

      rconvo = Conversation.initiate([sender, recipient], true)
      message = rconvo.add_message(sender, 'test')
      convo = sender.conversations.first
      expect(convo.last_authored_at).to eql expected_times.first
      expect(convo.visible_last_authored_at).to eql expected_times.first

      convo.remove_messages(message)
      expect(convo.last_authored_at).to eql expected_times.first
      expect(convo.visible_last_authored_at).to be_nil

      convo.add_message('bulk message', :update_for_sender => false)
      convo.reload
      expect(convo.last_authored_at).to eql expected_times.last
      expect(convo.visible_last_authored_at).to eql expected_times.last
    end

    it "should deliver the message to unsubscribed participants but not alert them" do
      recipients = create_users(5, return_type: :record)
      Conversation.initiate([sender] + recipients, false).add_message(sender, 'test')

      recipient = recipients.last
      rconvo = recipient.conversations.first
      expect(rconvo.unread?).to be_truthy
      rconvo.update_attributes(:subscribed => false)
      expect(rconvo.unread?).to be_falsey

      convo = sender.conversations.first
      message = convo.add_message('another test')
      message.update_attribute(:created_at, Time.now.utc + 1.minute)

      expect(rconvo.reload.unread?).to be_falsey
      rconvo.update_attributes(:subscribed => true)
      expect(rconvo.unread?).to be_truthy
    end

    it "should only alert message participants" do
      recipients = create_users(5, return_type: :record)
      convo = Conversation.initiate([sender] + recipients, false)
      convo.add_message(sender, 'test')

      recipient = recipients.last
      rconvo = recipient.conversations.first
      expect(rconvo.unread?).to be_truthy
      rconvo.update_attribute(:workflow_state, "read")

      convo.add_message(sender, 'another test', :only_users => [recipients.first])

      expect(rconvo.reload.unread?).to be_falsey
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
        expect(u1.enrollments.size).to eql 3

        conversation = Conversation.initiate([u1, u2], true)

        expect(conversation.current_context_strings(1)).to eql [course1.asset_string]
        expect(u1.conversation_context_codes.sort).to eql [course1.asset_string, course2.asset_string].sort # just once
      end
    end

    context "initial tags" do
      it "should save all valid tags on the conversation" do # NOTE: this will change if/when we allow arbitrary tags
        u1 = student_in_course(:active_all => true).user
        u2 = student_in_course(:active_all => true, :course => @course).user
        conversation = Conversation.initiate([u1, u2], true)
        conversation.add_message(u1, 'test', :tags => [@course.asset_string, "asdf", "lol"])
        expect(conversation.tags).to eql [@course.asset_string]
      end

      it "should set initial empty tags on the conversation and conversation_participant" do
        u1 = student_in_course.user
        u2 = student_in_course(:course => @course).user
        conversation = Conversation.initiate([u1, u2], true)
        expect(conversation.read_attribute(:tags)).not_to be_nil
        expect(conversation.tags).to eql []
        expect(u1.all_conversations.first.read_attribute(:tags)).not_to be_nil
        expect(u1.all_conversations.first.tags).to eql []
        expect(u2.all_conversations.first.read_attribute(:tags)).not_to be_nil
        expect(u2.all_conversations.first.tags).to eql []
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
        expect(conversation.tags).to eql [@course1.asset_string]
      end

      it "should save all visible tags on the conversation_participant" do
        u1 = student_in_course(:active_all => true).user
        u2 = student_in_course(:active_all => true, :course => @course).user
        u3 = user
        conversation = Conversation.initiate([u1, u2, u3], false)
        conversation.add_message(u1, 'test', :tags => [@course.asset_string])
        expect(conversation.tags).to eql [@course.asset_string]
        expect(u1.conversations.first.tags).to eql [@course.asset_string]
        expect(u2.conversations.first.tags).to eql [@course.asset_string]
        expect(u3.conversations.first.tags).to eql []
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
        expect(conversation.tags.sort).to eql [@course1.asset_string, @course2.asset_string].sort
        expect(u1.conversations.first.tags).to eql [@course1.asset_string]
        expect(u2.conversations.first.tags.sort).to eql [@course1.asset_string, @course2.asset_string].sort
        expect(u3.conversations.first.tags).to eql [@course2.asset_string]
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
        expect(conversation.tags).to eql [@course1.asset_string]
        expect(u1.conversations.first.tags).to eql [@course1.asset_string]
        expect(u2.conversations.first.tags).to eql [@course1.asset_string] # just the one, since it was explicit
        expect(u3.conversations.first.tags).to eql [@course2.asset_string] # not in course1, so fall back to common ones (i.e. course2)
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
          expect(user1.conversations.first.tags.sort).to eql [course1.asset_string, course2.asset_string].sort
          expect(user2.conversations.first.tags.sort).to eql [course1.asset_string, course2.asset_string].sort
        end
      end
    end

    context "deletion" do
      it "should remove tags when all messages are deleted" do
        u1 = student_in_course(:active_all => true).user
        u2 = student_in_course(:active_all => true, :course => @course).user
        conversation = Conversation.initiate([u1, u2], true)
        conversation.add_message(u1, 'test')
        expect(conversation.tags).to eql [@course.asset_string]
        cp1 = u1.conversations.first
        expect(cp1.tags).to eql [@course.asset_string]
        cp2 = u2.conversations.first
        expect(cp2.tags).to eql [@course.asset_string]

        cp2.remove_messages(:all)
        expect(cp2.tags).to eql []
        
        # no change here
        expect(cp1.reload.tags).to eql [@course.asset_string]
        expect(conversation.reload.tags).to eql [@course.asset_string]
      end
    end

    context "subsequent tags" do
      let_once(:course1) { @course1 = course(active_all: true) }
      let_once(:course2) { @course2 = course(active_all: true) }
      let_once(:u1) { student_in_course(active_all: true, course: course1).user }
      let_once(:u2) { student_in_course(active_all: true, course: course1).user }
      let_once(:u3) { student_in_course(active_all: true, course: course2).user }
      let_once(:conversation) do
        @course2.enroll_student(u2).update_attribute(:workflow_state, 'active')
        conversation = Conversation.initiate([u1, u2, u3], false)
        conversation.add_message(u1, 'test', :tags => [@course1.asset_string])
        conversation
      end

      it "should add new tags to the conversation" do
        expect(conversation.tags).to eql [@course1.asset_string]

        conversation.add_message(u1, 'another', :tags => [@course2.asset_string])
        expect(conversation.tags.sort).to eql [@course1.asset_string, @course2.asset_string].sort
      end

      it "should add new visible tags to the conversation_participant" do
        expect(u1.conversations.first.tags).to eq [@course1.asset_string]
        expect(u2.conversations.first.tags).to eq [@course1.asset_string]
        expect(u3.conversations.first.tags).to eq [@course2.asset_string]

        conversation.add_message(u1, 'another', :tags => [@course2.asset_string, "course_0"])
        expect(u1.conversations.first.tags).to eq [@course1.asset_string]
        expect(u2.conversations.first.tags.sort).to eq [@course1.asset_string, @course2.asset_string].sort
        expect(u3.conversations.first.tags).to eq [@course2.asset_string]
      end

      it "should ignore conversation_participants without a valid user" do
        expect(u1.conversations.first.tags).to eq [@course1.asset_string]
        expect(u2.conversations.first.tags).to eq [@course1.asset_string]
        expect(u3.conversations.first.tags).to eq [@course2.asset_string]
        broken_one = u3.conversations.first
        ConversationParticipant.where(id: broken_one).update_all(user_id: -1, tags: '')

        conversation.reload
        conversation.add_message(u1, 'another', :tags => [@course2.asset_string, "course_0"])
        expect(u1.conversations.first.tags).to eq [@course1.asset_string]
        expect(u2.conversations.first.tags.sort).to eq [@course1.asset_string]
        expect(broken_one.reload.tags).to eq []
      end
    end

    context "private conversations" do
      let_once(:course1) { @course1 = course(active_all: true) }
      let_once(:course2) { @course2 = course(active_all: true) }
      let_once(:u1) { student_in_course(active_all: true, course: course1).user }
      let_once(:u2) { student_in_course(active_all: true, course: course1).user }

      it "should save new visible tags on the conversation_message_participant" do
        @course2.enroll_student(u1).update_attribute(:workflow_state, 'active')
        @course2.enroll_student(u2).update_attribute(:workflow_state, 'active')
        conversation = Conversation.initiate([u1, u2], true)
        conversation.add_message(u1, 'test', :tags => [@course1.asset_string])
        cp = u2.conversations.first
        expect(cp.messages.human.first.tags).to eql [@course1.asset_string]

        conversation.add_message(u1, 'another', :tags => [@course2.asset_string, "course_0"])
        expect(cp.messages.human.first.tags).to eql [@course2.asset_string]
      end

      it "should save the previous message tags on the conversation_message_participant if there are no new visible ones" do
        conversation = Conversation.initiate([u1, u2], true)
        conversation.add_message(u1, 'test', :tags => [@course1.asset_string])
        cp = u2.conversations.first
        expect(cp.messages.human.first.tags).to eql [@course1.asset_string]

        conversation.add_message(u1, 'another', :tags => ["course_0"])
        expect(cp.messages.human.first.tags).to eql [@course1.asset_string]
      end

      it "should recompute the conversation_participant's tags when removing messages" do
        @course2.enroll_student(u1).update_attribute(:workflow_state, 'active')
        @course2.enroll_student(u2).update_attribute(:workflow_state, 'active')
        conversation = Conversation.initiate([u1, u2], true)
        conversation.add_message(u1, 'test', :tags => [@course1.asset_string])
        cp = u2.conversations.first
        expect(cp.tags).to eql [@course1.asset_string]
        expect(cp.messages.human.first.tags).to eql [@course1.asset_string]

        conversation.add_message(u1, 'another', :tags => [@course2.asset_string])
        expect(cp.reload.tags.sort).to eql [@course1.asset_string, @course2.asset_string].sort
        expect(cp.messages.human.first.tags).to eql [@course2.asset_string]

        cp.remove_messages(cp.messages.human.first)
        expect(cp.reload.tags).to eql [@course1.asset_string]
      end
    end

    context "group conversations" do
      let_once(:course1) { @course1 = course(active_all: true) }
      let_once(:course2) { @course2 = course(active_all: true) }
      let_once(:u1) { student_in_course(active_all: true, course: course1).user }
      let_once(:u2) { student_in_course(active_all: true, course: course1).user }

      it "should not save tags on the conversation_message_participant" do
        u3 = student_in_course(:active_all => true, :course => @course1).user
        conversation = Conversation.initiate([u1, u2, u3], false)
        conversation.add_message(u1, 'test', :tags => [@course1.asset_string])
        expect(u1.conversations.first.messages.human.first.tags).to eql []
        expect(u2.conversations.first.messages.human.first.tags).to eql []
        expect(u3.conversations.first.messages.human.first.tags).to eql []
      end

      it "should not recompute the conversation_participant's tags when removing messages" do
        @course2.enroll_student(u2).update_attribute(:workflow_state, 'active')
        u3 = student_in_course(:active_all => true, :course => @course2).user
        conversation = Conversation.initiate([u1, u2, u3], false)
        conversation.add_message(u1, 'test', :tags => [@course1.asset_string])
        cp = u2.conversations.first
        expect(cp.tags).to eql [@course1.asset_string]

        conversation.add_message(u1, 'another', :tags => [@course2.asset_string])
        expect(cp.reload.tags.sort).to eql [@course1.asset_string, @course2.asset_string].sort

        cp.remove_messages(cp.messages.human.first)
        expect(cp.reload.tags.sort).to eql [@course1.asset_string, @course2.asset_string].sort
      end

      it "should add tags specified along with new recipients" do
        @course2.enroll_student(u2).update_attribute(:workflow_state, 'active')
        u3 = student_in_course(:active_all => true, :course => @course2).user
        u4 = student_in_course(:active_all => true, :course => @course2).user
        conversation = Conversation.initiate([u1, u2, u3], false)
        conversation.add_message(u1, 'test', :tags => [@course1.asset_string])
        expect(conversation.tags).to eql [@course1.asset_string]
        expect(u1.conversations.first.tags).to eql [@course1.asset_string]
        expect(u2.conversations.first.tags).to eql [@course1.asset_string]
        expect(u3.conversations.first.tags).to eql [@course2.asset_string]

        conversation.add_participants(u2, [u4], :tags => [@course2.asset_string])
        expect(conversation.reload.tags.sort).to eql [@course1.asset_string, @course2.asset_string].sort
        expect(u1.conversations.first.tags).to eql [@course1.asset_string]
        expect(u2.conversations.first.tags.sort).to eql [@course1.asset_string, @course2.asset_string].sort
        expect(u3.conversations.first.tags).to eql [@course2.asset_string]
        expect(u4.conversations.first.tags).to eql [@course2.asset_string]
      end
    end

    context "migration" do
      before :once do
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
        expect(@conversation.tags).to eql []
        expect(@u1.conversations.first.tags).to eql []
        expect(@u2.conversations.first.tags).to eql []
        expect(@u3.conversations.first.tags).to eql []
      end

      it "should set the default tags when migrating" do
        @conversation.migrate_context_tags!

        expect(@conversation.tags.sort).to eql [@course1.asset_string, @course2.asset_string].sort
        expect(@u1.conversations.first.tags).to eql [@course1.asset_string]
        expect(@u2.conversations.first.tags.sort).to eql [@course1.asset_string, @course2.asset_string].sort
        expect(@u3.conversations.first.tags).to eql [@course2.asset_string]
      end

      it "should ignore conversation_participants without a user" do
        broken_one = @u3.conversations.first
        ConversationParticipant.where(id: broken_one).update_all(user_id: -1)

        @conversation.migrate_context_tags!

        expect(@conversation.tags).to eql [@course1.asset_string] # no course2 since participant is broken
        expect(@u1.conversations.first.tags).to eql [@course1.asset_string]
        expect(@u2.conversations.first.tags).to eql [@course1.asset_string]
        expect(broken_one.reload.tags).to eql [] # skipped
      end
    end

    context 'tag updates' do
      before :once do
        @teacher    = teacher_in_course(:active_all => true).user
        @student    = student_in_course(:active_all => true, :course => @course).user
        @old_course = @course
      end

      let_once(:student1) { student_in_course(:active_all => true, :course => @old_course).user }
      let_once(:student2) { student_in_course(:active_all => true, :course => @old_course).user }

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
          expect(participant.tags).to eq [new_course.asset_string]
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
          expect(participant.tags).to eq [@old_course.asset_string]
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
          expect(participant.tags.sort).to eq [@old_course, old_course2].map(&:asset_string).sort
        end
      end

      it "should include concluded group contexts when no active ones exist" do
        group      = Group.create!(:context => @old_course)
        [student1, student2].each { |s| group.users << s }

        conversation = Conversation.initiate([student1, student2], true)
        conversation.add_message(student1, 'first message')

        @old_course.complete!
        group.complete!

        conversation.add_message(student2, 'second message')

        conversation.conversation_participants.each do |participant|
          participant.reload
          expect(participant.tags).to include(group.asset_string)
        end
      end

      it "should replace concluded group contexts with active ones" do
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
          expect(participant.tags.sort).to eq [new_group, new_course].map(&:asset_string).sort
        end
      end
    end
  end

  context "root_account_ids" do
    it "should always be ordered" do
      conversation = Conversation.create
      conversation.update_attribute :root_account_ids, [3, 2, 1]
      expect(conversation.root_account_ids).to eql [1, 2, 3]
    end

    it "should be saved on the conversation when adding a message" do
      u1 = user
      u2 = user
      conversation = Conversation.initiate([u1, u2], true)
      conversation.add_message(u1, 'ohai', :root_account_id => 1)
      conversation.add_message(u2, 'ohai yourself', :root_account_id => 2)
      expect(conversation.root_account_ids).to eql [1, 2]
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

    expect { source.reload }.to raise_error(ActiveRecord::RecordNotFound)
    expect(ConversationParticipant.where(conversation_id: source)).to eq []
    expect(ConversationMessage.where(conversation_id: source)).to eq []

    target.reload
    expect(target.participants(true).map(&:id)).to eq [sender.id, target_user.id]
    expect(target_user.reload.all_conversations.map(&:conversation)).to eq [target]
    cp = target_user.all_conversations.first
    expect(cp.messages.length).to eq message_count
  end

  describe "merge_into" do
    # non-sharding cases are covered by ConversationParticipant#move_to_user specs

    context "sharding" do
      specs_require_sharding

      before :once do
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
          expect(@conversation2.associated_shards.sort_by(&:id)).to eq [Shard.default, @shard1].sort_by(&:id)
        end

        it "user from another shard participating in source conversation only" do
          merge_and_check(@sender, @conversation1, @conversation2, @user2, nil)
          expect(@conversation2.associated_shards.sort_by(&:id)).to eq [Shard.default, @shard1].sort_by(&:id)
        end
      end

      context "differing shards" do
        it "user from source shard participating in both conversations" do
          merge_and_check(@sender, @conversation1, @conversation3, @user1, @user1)
          expect(@conversation3.associated_shards.sort_by(&:id)).to eq [@shard1, Shard.default].sort_by(&:id)
        end

        it "user from destination shard participating in both conversations" do
          merge_and_check(@sender, @conversation1, @conversation3, @user2, @user2)
          expect(@conversation3.associated_shards.sort_by(&:id)).to eq [@shard1, Shard.default].sort_by(&:id)
        end

        it "user from third shard participating in both conversations" do
          merge_and_check(@sender, @conversation1, @conversation3, @user3, @user3)
          expect(@conversation3.associated_shards.sort_by(&:id)).to eq [Shard.default, @shard1, @shard2].sort_by(&:id)
        end

        it "user from source shard participating in source conversation only" do
          merge_and_check(@sender, @conversation1, @conversation3, @user1, nil)
          expect(@conversation3.associated_shards.sort_by(&:id)).to eq [@shard1, Shard.default].sort_by(&:id)
        end

        it "user from destination shard participating in source conversation only" do
          merge_and_check(@sender, @conversation1, @conversation3, @user2, nil)
          expect(@conversation3.associated_shards.sort_by(&:id)).to eq [@shard1, Shard.default].sort_by(&:id)
        end

        it "user from third shard participating in source conversation only" do
          merge_and_check(@sender, @conversation1, @conversation3, @user3, nil)
          expect(@conversation3.associated_shards.sort_by(&:id)).to eq [Shard.default, @shard1, @shard2].sort_by(&:id)
        end
      end
    end
  end
end
