# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

describe Notifier do
  describe "#send_notification" do
    it "caches messages for inspection in test" do
      group_user = user_with_communication_channel(active_all: true)
      group_membership = group_with_user(user: group_user, active_all: true)
      notification = Notification.create!(name: "New Context Group Membership", category: "Registration")
      to_list = [group_user]
      dispatch = :test_dispatch
      message = double("message")

      expect(DelayedNotification).to receive(:delay_if_production).and_call_original
      expect(DelayedNotification).to receive(:process).with(
        kind_of(ActiveRecord::Base),
        kind_of(Notification),
        ["user_#{group_user.id}"],
        nil
      ).and_return([message])

      subject.send_notification(group_membership, dispatch, notification, to_list)

      messages = group_membership.messages_sent[dispatch]
      expect(messages.size).to eq(1)
      expect(messages.first).to eq(message)
    end
  end
end
