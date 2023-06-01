# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

describe ConversationBatch do
  before :once do
    student_in_course(active_all: true)
    @user1 = @user
    @message = Conversation.build_message @user1, "hi all"
    student_in_course(active_all: true)
    @user2 = @user
    student_in_course(active_all: true)
    @user3 = @user
  end

  describe ".created_as_template?" do
    let(:message) { Conversation.build_message(@user, "lorem ipsum") }

    it "returns true for template messages" do
      expect(ConversationBatch.created_as_template?(message:)).to be true
    end

    it "returns false for non-template messages (messages that have a conversation_id)" do
      conversation = Conversation.create!
      message.conversation = conversation
      expect(ConversationBatch.created_as_template?(message:)).to be false
    end
  end

  context "generate" do
    it "creates an async batch" do
      batch = ConversationBatch.generate(@message, [@user2, @user3], :async)
      expect(batch).to be_created
      expect(batch.completion).to be < 1
    end

    it "creates a sync batch and run it" do
      start_count = ConversationMessage.count
      batch = ConversationBatch.generate(@message, [@user2, @user3], :sync)
      expect(batch).to be_sent
      expect(batch.completion).to be 1
      expect(batch.root_conversation_message.reload.conversation).to be_nil
      expect(ConversationMessage.count - start_count).to be 3 # the root message, plus the ones to each recipient
      expect(@user1.reload.unread_conversations_count).to be 0
      expect(@user1.all_conversations.size).to be 2
      expect(@user2.reload.unread_conversations_count).to be 1
      expect(@user3.reload.unread_conversations_count).to be 1
    end
  end

  context "deliver" do
    it "is sent to all recipients" do
      start_count = ConversationMessage.count
      batch = ConversationBatch.generate(@message, [@user2, @user3], :async)
      batch.deliver

      expect(batch).to be_sent
      expect(batch.completion).to be 1
      expect(batch.root_conversation_message.reload.conversation).to be_nil
      expect(ConversationMessage.count - start_count).to be 3 # the root message, plus the ones to each recipient
      expect(@user1.reload.unread_conversations_count).to be 0
      expect(@user1.all_conversations.size).to be 2
      expect(@user2.reload.unread_conversations_count).to be 1
      expect(@user3.reload.unread_conversations_count).to be 1
    end

    it "applies the tags to each conversation" do
      start_count = ConversationMessage.count
      g = @course.groups.create
      g.users << @user1 << @user2
      batch = ConversationBatch.generate(@message, [@user2, @user3], :async, tags: [g.asset_string])
      batch.deliver

      expect(ConversationMessage.count - start_count).to be 3 # the root message, plus the ones to each recipient
      expect(@user1.reload.unread_conversations_count).to be 0
      expect(@user1.all_conversations.size).to be 2
      expect(@user2.reload.unread_conversations_count).to be 1
      expect(@user2.conversations.first.tags).to eql [g.asset_string]
      expect(@user3.reload.unread_conversations_count).to be 1
      expect(@user3.conversations.first.tags).to eql [@course.asset_string] # not in group, so it falls back to common contexts
    end

    it "copies the attachment(s) to each conversation" do
      start_count = ConversationMessage.count
      attachment = attachment_model(context: @user1, folder: @user1.conversation_attachments_folder)
      @message = Conversation.build_message @user1, "hi all", attachment_ids: [attachment.id]

      batch = ConversationBatch.generate(@message, [@user2, @user3], :async)
      batch.deliver

      expect(ConversationMessage.count - start_count).to be 3
      ConversationMessage.all.each do |message|
        expect(message.attachments).to eq @message.attachments
      end
    end

    it "sends group messages" do
      start_count = Conversation.count
      batch = ConversationBatch.generate(@message, [@user, @user3], :async, group: true)
      batch.deliver
      expect(Conversation.count - start_count).to eq 2
      Conversation.all.each { |c| expect(c).not_to be_private }
    end

    context "sharding" do
      specs_require_sharding

      it "reuses existing private conversations" do
        @shard1.activate { @user4 = user_factory }
        conversation = @user1.initiate_conversation([@user4]).conversation
        conversation.add_message(@user1, "hello")
        batch = ConversationBatch.generate(@message, [@user3, @user4], :sync)
        expect(batch).to be_sent
        expect(batch.completion).to be 1
        expect(batch.root_conversation_message.reload.conversation).to be_nil
        expect(ConversationMessage.count).to be 4 # the root message, plus the ones to each recipient
        expect(@user1.reload.unread_conversations_count).to be 0
        expect(@user1.all_conversations.size).to be 2
        expect(@user3.reload.unread_conversations_count).to be 1
        expect(@user4.reload.unread_conversations_count).to be 1
      end
    end
  end
end
