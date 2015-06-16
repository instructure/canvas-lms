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
require 'db/migrate/20120502212620_fix_user_conversations_counts_for_all.rb'

describe 'FixUserConversationsCountsForAll' do
  describe "up" do
    it "should fix incorrect entries and correctly count already correct entries" do
      # Setup user with correct unread_conversations_count (2 unread convos)
      u1 = user
      2.times do
        c = u1.initiate_conversation([u1], false)
        c.add_message('Hello')
        c.add_message('Hello again')
        c.update_attribute(:workflow_state, 'unread')
      end
      # unread_conversations_count == 2

      # Setup user with wrong unread_conversations_count (negative)
      u2 = user
      1.times do
        c = u2.initiate_conversation([u2], false)
        c.add_message('Hello')
        c.add_message('Hello again')
        c.update_attribute(:workflow_state, 'unread')
      end
      # unread_conversations_count == 1
      u2.update_attribute(:unread_conversations_count, -3)

      # Setup user with wrong unread_conversations_count (too many)
      u3 = user
      3.times do
        c = u3.initiate_conversation([u3], false)
        c.add_message('Hello')
        c.add_message('Hello again')
        c.update_attribute(:workflow_state, 'unread')
      end
      # unread_conversations_count == 3
      u3.update_attribute(:unread_conversations_count, 10)

      FixUserConversationsCountsForAll.up

      expect(u1.reload.unread_conversations_count).to eq 2
      expect(u2.reload.unread_conversations_count).to eq 1
      expect(u3.reload.unread_conversations_count).to eq 3
    end

    it "should not count deleted entries" do
      # Setup user with some deleted conversations
      u1 = user
      2.times do
        c = u1.initiate_conversation([u1], false)
        c.add_message('Hello')
        c.add_message('Hello again')
        c.update_attribute(:workflow_state, 'unread')
      end
      1.times do
        c = u1.initiate_conversation([u1], false)
        c.add_message('Deleted myself')
        c.add_message('Empty yo')
        c.update_attribute(:workflow_state, 'unread')
        c.remove_messages(:all)         # delete conversation (and all messages)
      end
      # unread_conversations_count == 2

      # Setup user with only deleted conversations (should have count 0)
      u2 = user
      3.times do
        c = u2.initiate_conversation([u2], false)
        c.add_message('Hello')
        c.add_message('Hello again')
        c.update_attribute(:workflow_state, 'unread')
        c.remove_messages(:all)         # delete conversation (and all messages)
      end
      # unread_conversations_count == 0

      FixUserConversationsCountsForAll.up

      expect(u1.reload.unread_conversations_count).to eq 2
      expect(u2.reload.unread_conversations_count).to eq 0
    end
  end
end
