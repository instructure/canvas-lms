#
# Copyright (C) 2016 - present Instructure, Inc.
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

require_relative '../sharding_spec_helper'

describe DataFixup::FixConversationRootAccountIds do
  specs_require_sharding

  it 'should fix conversations with unglobalishized root account ids' do
    @shard1.activate do
      @account = account_model
      new_course = course_factory(:account => @account)
      u1 = user_factory
      u2 = user_factory
      conversation = Conversation.initiate([u1, u2], false, context_type: 'Course', context_id: new_course.id)
      conversation.root_account_ids = [@account.id] # unglobalize it
      conversation.save!

      part = conversation.conversation_participants.first
      part.root_account_ids = @account.id.to_s
      part.save!

      DataFixup::FixConversationRootAccountIds.run

      conversation.reload
      expect(conversation.root_account_ids).to eql [@account.global_id]

      part.reload
      expect(part.root_account_ids).to eql @account.global_id.to_s
    end
  end
end
