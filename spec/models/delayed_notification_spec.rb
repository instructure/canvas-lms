#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe DelayedNotification do
  describe '#process' do
    let(:group_user) { user_with_communication_channel(active_all: true) }
    let(:group_membership) { group_with_user(user: group_user, active_all: true) }
    let(:group_instance) { group_membership.group }
    let(:notification) { Notification.create!(name: "New Context Group Membership", category: "Registration") }

    it 'processes notifications' do
      messages = DelayedNotification.process(
      group_membership,
      notification,
      ["user_#{group_user.id}"],
      group_instance,
      nil
      )

      expect(messages.size).to eq 1
      messages.first.user == group_user
    end
 end

end

