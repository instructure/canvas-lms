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
require 'db/migrate/20120216163427_fix_user_merge_conversations.rb'

describe 'FixUserMergeConversations' do
  describe "up" do
    it "should work" do
      u1 = user
      u2 = user
      u3 = user

      c1 = Conversation.initiate([u1.id, u2.id], true)
      c1.participants << u1
      c1.update_attribute(:private_hash, 'no longer valid')
      c1.conversation_participants.size.should eql 3

      c2 = Conversation.initiate([u1.id, u3.id], true)
      c2.update_attribute(:private_hash, 'well this is clearly wrong')

      c3 = Conversation.initiate([u1.id, u3.id], true)

      FixUserMergeConversations.up

      c1.reload.conversation_participants.size.should eql 2
      c1.private_hash.should_not eql 'no longer valid'
      lambda { c2.reload }.should raise_error
    end
  end
end
