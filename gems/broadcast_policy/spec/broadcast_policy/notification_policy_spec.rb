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

require "active_record"
require "after_transaction_commit"

describe BroadcastPolicy::NotificationPolicy do
  let(:subject) do
    policy = BroadcastPolicy::NotificationPolicy.new(:test_notification)
    policy.to       = proc { ["user@example.com", "user2@example.com", MockSuspendedUser.new] }
    policy.whenever = proc { true }
    policy
  end

  let(:test_notification) { instance_double(ActiveRecord::Base) }
  let(:mock_connection) { instance_double(ActiveRecord::ConnectionAdapters::AbstractAdapter) }
  let(:mock_record_class) do
    Class.new(ActiveRecord::Base) do
      extend BroadcastPolicy::ClassMethods

      has_a_broadcast_policy
    end.tap do |klass|
      allow(klass).to receive(:connection).and_return(mock_connection)
    end
  end

  let(:record) { instance_double(mock_record_class, skip_broadcasts: false, class: mock_record_class) }

  before do
    allow(mock_connection).to receive(:after_transaction_commit).and_yield
    BroadcastPolicy.notifier = MockNotifier.new
    BroadcastPolicy.notification_finder = MockNotificationFinder.new(test_notification:)
  end

  it "send_notifications for each slice of users" do
    allow(BroadcastPolicy::NotificationPolicy).to receive(:slice_size).and_return(1)
    expect(BroadcastPolicy.notifier).to receive(:send_notification).twice
    subject.broadcast(record)
  end

  it "calls the notifier" do
    subject.broadcast(record)
    expect(BroadcastPolicy.notifier.messages.count).to eq(1)
  end

  it "broadcast message only to not suspended users" do
    subject.broadcast(record)
    expect(BroadcastPolicy.notifier.messages[0][:recipients].count).to eq(2)
  end

  it "does not send if skip_broadcasts is set" do
    allow(record).to receive(:skip_broadcasts).and_return(true)
    subject.broadcast(record)
    expect(BroadcastPolicy.notifier.messages).to be_empty
  end

  it "does not send if conditions are not met" do
    subject.whenever = ->(_) { false }
    subject.broadcast(record)
    expect(BroadcastPolicy.notifier.messages).to be_empty
  end

  it "does not send if there is not a recipient list" do
    subject.to = ->(_) {}
    subject.broadcast(record)
    expect(BroadcastPolicy.notifier.messages).to be_empty
  end

  it "sends even if there isn't data" do
    subject.data = ->(_) {}
    subject.broadcast(record)
    expect(BroadcastPolicy.notifier.messages).to_not be_empty
  end
end
