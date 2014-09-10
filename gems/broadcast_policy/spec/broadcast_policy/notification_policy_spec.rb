
require 'spec_helper'

describe BroadcastPolicy::NotificationPolicy do
  let(:subject) do
    policy = BroadcastPolicy::NotificationPolicy.new(:test_notification)
    policy.to       = ->(record) { ['user@example.com'] }
    policy.whenever = ->(record) { true }
    policy
  end

  let(:test_notification) { double(:test_notification) }

  before(:each) do
    BroadcastPolicy.notifier = MockNotifier.new
    BroadcastPolicy.notification_finder = MockNotificationFinder.new(test_notification: test_notification)
  end

  it "should call the notifier" do
    record = double('test record', skip_broadcasts: false, messages_failed: {})
    subject.broadcast(record)
    expect(BroadcastPolicy.notifier.messages.count).to eq(1)
  end

  it "should not send if skip_broadcasts is set" do
    record = double('test object', skip_broadcasts: true, messages_failed: {})
    subject.broadcast(record)
    expect(BroadcastPolicy.notifier.messages).to be_empty
  end

  it "should not send if conditions are not met" do
    record = double('test object', skip_broadcasts: false, messages_failed: {})
    subject.whenever = ->(r) { false }
    subject.broadcast(record)
    expect(BroadcastPolicy.notifier.messages).to be_empty
  end

  it "should not send if there is not a recipient list" do
    record = double('test object', skip_broadcasts: false, messages_failed: {})
    subject.to = ->(r) { nil }
    subject.broadcast(record)
    expect(BroadcastPolicy.notifier.messages).to be_empty
  end

  it "should not send if there isn't a proper context" do
    record = double('test object', skip_broadcasts: false, messages_failed: {})
    subject.context = ->(r) { raise Error.new }
    subject.broadcast(record)
    expect(BroadcastPolicy.notifier.messages).to be_empty
  end

  it "should log context exceptions" do
    record = double('test object', skip_broadcasts: false, messages_failed: {})
    subject.context = ->(r) { raise Error.new }
    subject.broadcast(record)
    expect(record.messages_failed.keys).to eq([:test_notification])
  end

  it "should not send if there isn't proper data" do
    record = double('test object', skip_broadcasts: false, messages_failed: {})
    subject.data = ->(r) { raise Error.new }
    subject.broadcast(record)
    expect(BroadcastPolicy.notifier.messages).to be_empty
  end

  it "should log data exceptions" do
    record = double('test object', skip_broadcasts: false, messages_failed: {})
    subject.data = ->(r) { raise Error.new }
    subject.broadcast(record)
    expect(record.messages_failed.keys).to eq([:test_notification])
  end
end 
