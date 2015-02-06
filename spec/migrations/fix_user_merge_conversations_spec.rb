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
      skip "no longer possible to create bad data due to db constraint"
      u1 = user
      u2 = user
      u3 = user

      c1 = Conversation.initiate([u1, u2], true)
      c1.conversation_participants.create!(:user => u1)
      c1.update_attribute(:private_hash, 'no longer valid')
      expect(c1.conversation_participants.size).to eql 3

      c2 = Conversation.initiate([u1, u3], true)
      c2.update_attribute(:private_hash, 'well this is clearly wrong')

      c3 = Conversation.initiate([u1, u3], true)

      FixUserMergeConversations.up

      expect(c1.reload.conversation_participants.size).to eql 2
      expect(c1.private_hash).not_to eql 'no longer valid'
      expect { c2.reload }.to raise_error
    end
  end
end
