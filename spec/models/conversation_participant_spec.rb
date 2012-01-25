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
end
