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
  describe "broadcast policy endpoint" do
    # Our notifier class is an entry point for the broadcast policy system.
    # This is not the best place for this test, but it is the only place
    # We document the behaviour for further reference.
    # Anytime a model is saved, it will trigger BroadcastPolicy.notifier.new.send_notification(*args)
    #
    context "when broadcast policy event criteria triggers the notification" do
      subject { record.save! }

      let!(:user) { user_with_communication_channel(active_all: true) }
      let(:record) { AccountUser.new(account: Account.default, user:) }
      let(:notification) { BroadcastPolicy.notification_finder.by_name(policy_name) }
      let(:policy_name) { "New Account User" }
      let(:to_list) { [user] }
      let!(:notification_policy) do
        NotificationPolicy.create!(
          notification: account_user_notification,
          communication_channel_id: user.communication_channels.first,
          frequency: Notification::FREQ_IMMEDIATELY
        )
      end
      let(:notification_attributes) do
        {
          "id" => 62,
          "name" => policy_name,
          "subject" => "No Subject",
          "category" => "Registration",
          "delay_for" => 0,
          "priority" => false
        }
      end
      let!(:account_user_notification) { Notification.create!(notification_attributes) }

      before do
        allow(DelayedNotification).to receive(:delay_if_production).and_call_original
      end

      it "starts the processing" do
        expect_any_instance_of(Notifier)
          .to receive(:send_notification)
          .with(
            record,
            policy_name,
            notification,
            [user],
            nil
          )

        subject
      end

      it "n_strands the job for new account user notifications" do
        expect(DelayedNotification).to receive(:delay_if_production).with(
          priority: 30,
          n_strand: ["delayed_notification", record.account.root_account.global_id]
        )

        subject
      end
    end
  end

  describe "#send_notification" do
    it "caches messages for inspection in test" do
      group_user = user_with_communication_channel(active_all: true)
      group_membership = group_with_user(user: group_user, active_all: true)
      notification = Notification.create!(name: "New Context Group Membership", category: "Registration")
      to_list = [group_user]
      dispatch = :test_dispatch
      message = double("message")

      expect(DelayedNotification).to receive(:delay_if_production)
        .with(priority: 30)
        .and_call_original
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
