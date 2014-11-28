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
require 'db/migrate/20120402054921_populate_conversation_root_account_ids.rb'

describe 'PopulateConversationRootAccountIds' do
  describe "up" do
    it "should work" do
      skip "no longer possible since context_messages no longer exists"
      u = user

      # messages w/ account contexts
      u1 = user
      a1a = Account.default
      a1b = Account.create
      cn1 = Conversation.initiate([u, u1], true)
      cn1.add_message(u, "test1").update_attribute(:context, a1a)
      cn1.add_message(u, "test2").update_attribute(:context, a1a)
      cn1.add_message(u, "test3").update_attribute(:context, a1b)
      expect(cn1.root_account_ids).to eql []

      # context message on course
      u2 = user
      a2 = Account.create
      c2 = course(:account => a2)
      cn2 = Conversation.initiate([u, u2], true)
      cn2.add_message(u, "test")
      Conversation.connection.execute "INSERT INTO context_messages(context_id, context_type) VALUES(#{c2.id}, 'Course')"
      cn2.conversation_messages.update_all("context_message_id = (SELECT id FROM context_messages ORDER BY id DESC LIMIT 1)")
      expect(cn2.root_account_ids).to eql []

      # context message on group
      u3 = user
      a3 = Account.create
      g3 = group(:group_context => a3)
      
      cn3 = Conversation.initiate([u, u3], true)
      cn3.add_message(u, "test")
      Conversation.connection.execute "INSERT INTO context_messages(context_id, context_type) VALUES(#{g3.id}, 'Group')"
      cn3.conversation_messages.update_all("context_message_id = (SELECT id FROM context_messages ORDER BY id DESC LIMIT 1)")
      expect(cn3.root_account_ids).to eql []

      # submission
      u4 = user
      a4 = Account.create
      c4 = course(:account => a4, :active_all => true)
      student_in_course(:user => u4, :course => c4, :active_all => true)
      as4 = c4.assignments.create
      s4 = as4.submit_homework(u4, :submission_type => "online_text_entry", :body => "")
      cn4 = Conversation.initiate([u, u4], true)
      cn4.add_message(u, '').update_attribute(:asset, s4)
      expect(cn4.root_account_ids).to eql []

      # no root account info available
      u5 = user
      cn5 = Conversation.initiate([u, u5], true)
      cn5.add_message(u, "test")

      PopulateConversationRootAccountIds.up

      expect(cn1.reload.root_account_ids).to eql [a1a.id, a1b.id]
      expect(cn2.reload.root_account_ids).to eql [a2.id]
      expect(cn3.reload.root_account_ids).to eql [a3.id]
      expect(cn4.reload.root_account_ids).to eql [a4.id]
      expect(cn5.reload.root_account_ids).to eql []
    end
  end
end
