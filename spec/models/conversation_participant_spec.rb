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
end
