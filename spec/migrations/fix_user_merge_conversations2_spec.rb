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
      pending("can't create the bad state anymore due to foreign keys preventing it")
      u1 = user
      u2 = user
      u3 = user

      # set up borked conversation that is partially merged...
      # conversation deleted, cp's and cmps orphaned,
      # and cm on the target conversation
      borked = Conversation.initiate([u1.id, u2.id], true)
      borked_cps = borked.conversation_participants.all
      borked_cmps = borked_cps.map(&:conversation_message_participants).flatten
      m1 = borked.add_message(u1, "test")
      Conversation.delete_all(:id => borked.id) # bypass callbacks

      correct = Conversation.initiate([u1.id, u2.id], true)
      m2 = correct.add_message(u1, "test2")
      correct.conversation_participants.each { |cp| cp.update_attribute :workflow_state, 'archived'}

      # put it the message on the correct conversation
      m1.update_attribute :conversation_id, correct.id

      unrelated = Conversation.initiate([u1.id, u3.id], true)
      unrelated.add_message(u1, "test3")

      FixUserMergeConversations2.up

      correct.reload
      unrelated.reload

      # these are gone for reals now
      lambda { borked.reload }.should raise_error
      borked_cps.each { |cp| lambda { cp.reload }.should raise_error }

      # these are moved to the right place
      borked_cmps.each do |cmp|
        lambda { cmp.reload }.should_not raise_error
        cmp.conversation_participant.conversation.should eql correct
      end
      correct.conversation_participants.each do |cp|
        cp.messages.size.should eql 2
        cp.message_count.should eql 2
      end
      # got bumped out of archived by the merged/deleted ones
      correct.conversation_participants.default.size.should eql 2
      correct.conversation_participants.unread.size.should eql 1

      # no changes here
      unrelated.conversation_participants.each do |cp|
        cp.messages.size.should eql 1
        cp.message_count.should eql 1
      end
    end
  end
end
