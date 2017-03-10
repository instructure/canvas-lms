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
require 'db/migrate/20120404230916_fix_user_merge_conversations2.rb'

describe 'FixUserMergeConversations2' do
  describe "up" do
    it "should work" do
      skip("can't create the bad state anymore due to foreign keys preventing it")
      u1 = user
      u2 = user
      u3 = user

      # set up borked conversation that is partially merged...
      # conversation deleted, cp's and cmps orphaned,
      # and cm on the target conversation
      borked = Conversation.initiate([u1, u2], true)
      borked_cps = borked.conversation_participants.to_a
      borked_cmps = borked_cps.map(&:conversation_message_participants).flatten
      m1 = borked.add_message(u1, "test")
      Conversation.where(:id => borked).delete_all # bypass callbacks

      correct = Conversation.initiate([u1, u2], true)
      m2 = correct.add_message(u1, "test2")
      correct.conversation_participants.each { |cp| cp.update_attribute :workflow_state, 'archived'}

      # put it the message on the correct conversation
      m1.update_attribute :conversation_id, correct.id

      unrelated = Conversation.initiate([u1, u3], true)
      unrelated.add_message(u1, "test3")

      FixUserMergeConversations2.up

      correct.reload
      unrelated.reload

      # these are gone for reals now
      expect { borked.reload }.to raise_error(ActiveRecord::RecordNotFound)
      borked_cps.each { |cp| expect { cp.reload }.to raise_error(ActiveRecord::RecordNotFound) }

      # these are moved to the right place
      borked_cmps.each do |cmp|
        expect { cmp.reload }.not_to raise_error
        expect(cmp.conversation_participant.conversation).to eql correct
      end
      correct.conversation_participants.each do |cp|
        expect(cp.messages.size).to eql 2
        expect(cp.message_count).to eql 2
      end
      # got bumped out of archived by the merged/deleted ones
      expect(correct.conversation_participants.default.size).to eql 2
      expect(correct.conversation_participants.unread.size).to eql 1

      # no changes here
      unrelated.conversation_participants.each do |cp|
        expect(cp.messages.size).to eql 1
        expect(cp.message_count).to eql 1
      end
    end
  end
end
