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

describe ConversationBatch do
  before :once do
    student_in_course(:active_all => true)
    @user1 = @user
    @message = Conversation.build_message @user1, "hi all"
    student_in_course(:active_all => true)
    @user2 = @user
    student_in_course(:active_all => true)
    @user3 = @user
  end

  context "generate" do
    it "should create an async batch" do
      batch = ConversationBatch.generate(@message, [@user2, @user3], :async)
      batch.should be_created
      batch.completion.should < 1
    end

    it "should create a sync batch and run it" do
      start_count = ConversationMessage.count
      batch = ConversationBatch.generate(@message, [@user2, @user3], :sync)
      batch.should be_sent
      batch.completion.should eql 1
      batch.root_conversation_message.reload.conversation.should be_nil
      (ConversationMessage.count - start_count).should eql 3 # the root message, plus the ones to each recipient
      @user1.reload.unread_conversations_count.should eql 0
      @user1.all_conversations.size.should eql 2
      @user2.reload.unread_conversations_count.should eql 1
      @user3.reload.unread_conversations_count.should eql 1
    end
  end

  context "deliver" do
    it "should be sent to all recipients" do
      start_count = ConversationMessage.count
      batch = ConversationBatch.generate(@message, [@user2, @user3], :async)
      batch.deliver

      batch.should be_sent
      batch.completion.should eql 1
      batch.root_conversation_message.reload.conversation.should be_nil
      (ConversationMessage.count - start_count).should eql 3 # the root message, plus the ones to each recipient
      @user1.reload.unread_conversations_count.should eql 0
      @user1.all_conversations.size.should eql 2
      @user2.reload.unread_conversations_count.should eql 1
      @user3.reload.unread_conversations_count.should eql 1
    end

    it "should apply the tags to each conversation" do
      start_count = ConversationMessage.count
      g = @course.groups.create
      g.users << @user1 << @user2
      batch = ConversationBatch.generate(@message, [@user2, @user3], :async, :tags => [g.asset_string])
      batch.deliver

      (ConversationMessage.count - start_count).should eql 3 # the root message, plus the ones to each recipient
      @user1.reload.unread_conversations_count.should eql 0
      @user1.all_conversations.size.should eql 2
      @user2.reload.unread_conversations_count.should eql 1
      @user2.conversations.first.tags.should eql [g.asset_string]
      @user3.reload.unread_conversations_count.should eql 1
      @user3.conversations.first.tags.should eql [@course.asset_string] # not in group, so it falls back to common contexts
    end

    it "should copy the attachment(s) to each conversation" do
      start_count = ConversationMessage.count
      attachment = attachment_model(:context => @user1, :folder => @user1.conversation_attachments_folder)
      @message = Conversation.build_message @user1, "hi all", :attachment_ids => [attachment.id]

      batch = ConversationBatch.generate(@message, [@user2, @user3], :async)
      batch.deliver

      (ConversationMessage.count - start_count).should eql 3
      ConversationMessage.all.each do |message|
        message.attachments.should == @message.attachments
      end
    end

    it "should send group messages" do
      start_count = Conversation.count
      batch = ConversationBatch.generate(@message, [@user, @user3], :async, group: true)
      batch.deliver
      (Conversation.count - start_count).should == 2
      Conversation.all.each { |c| c.should_not be_private }
    end

    context "sharding" do
      specs_require_sharding

      it "should reuse existing private conversations" do
        @shard1.activate { @user4 = user }
        conversation = @user1.initiate_conversation([@user4]).conversation
        conversation.add_message(@user1, "hello")
        batch = ConversationBatch.generate(@message, [@user3, @user4], :sync)
        batch.should be_sent
        batch.completion.should eql 1
        batch.root_conversation_message.reload.conversation.should be_nil
        ConversationMessage.count.should eql 4 # the root message, plus the ones to each recipient
        @user1.reload.unread_conversations_count.should eql 0
        @user1.all_conversations.size.should eql 2
        @user3.reload.unread_conversations_count.should eql 1
        @user4.reload.unread_conversations_count.should eql 1
      end
    end
  end
end
