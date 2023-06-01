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

require_relative "../spec_helper"

describe BroadcastPolicy::NotificationPolicy do
  let(:subject) do
    policy = BroadcastPolicy::NotificationPolicy.new(:test_notification)
    policy.to       = proc { ["user@example.com", "user2@example.com", MockSuspendedUser.new] }
    policy.whenever = proc { true }
    policy
  end

  let(:test_notification) { double(:test_notification) }
  let(:test_connection_class) do
    Class.new do
      def after_transaction_commit
        yield
      end
    end
  end

  before do
    BroadcastPolicy.notifier = MockNotifier.new
    BroadcastPolicy.notification_finder = MockNotificationFinder.new(test_notification:)
  end

  it "send_notifications for each slice of users" do
    allow(BroadcastPolicy::NotificationPolicy).to receive(:slice_size).and_return(1)
    record = double("test record", skip_broadcasts: false, class: double(connection: test_connection_class.new))
    expect(BroadcastPolicy.notifier).to receive(:send_notification).twice
    subject.broadcast(record)
  end

  it "calls the notifier" do
    record = double("test record", skip_broadcasts: false, class: double(connection: test_connection_class.new))
    subject.broadcast(record)
    expect(BroadcastPolicy.notifier.messages.count).to eq(1)
  end

  it "broadcast message only to not suspended users" do
    record = double("test record", skip_broadcasts: false, class: double(connection: test_connection_class.new))
    subject.broadcast(record)
    expect(BroadcastPolicy.notifier.messages[0][:recipients].count).to eq(2)
  end

  it "does not send if skip_broadcasts is set" do
    record = double("test object", skip_broadcasts: true)
    subject.broadcast(record)
    expect(BroadcastPolicy.notifier.messages).to be_empty
  end

  it "does not send if conditions are not met" do
    record = double("test object", skip_broadcasts: false)
    subject.whenever = ->(_) { false }
    subject.broadcast(record)
    expect(BroadcastPolicy.notifier.messages).to be_empty
  end

  it "does not send if there is not a recipient list" do
    record = double("test object", skip_broadcasts: false, class: double(connection: test_connection_class.new))
    subject.to = ->(_) {}
    subject.broadcast(record)
    expect(BroadcastPolicy.notifier.messages).to be_empty
  end

  it "sends even if there isn't data" do
    record = double("test object", skip_broadcasts: false, class: double(connection: test_connection_class.new))
    subject.data = ->(_) {}
    subject.broadcast(record)
    expect(BroadcastPolicy.notifier.messages).to_not be_empty
  end
end
