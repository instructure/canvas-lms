require 'spec_helper'

describe BroadcastPolicy::PolicyList do
  describe ".new" do
    it "creates a new notification list" do
      expect(subject.notifications).to eq([])
    end
  end

  describe "#populate" do
    it "stores notification policies" do
      subject.populate do
        dispatch :foo
        to       { 'test@example.com' }
        whenever { true }
      end

      expect(subject.notifications.length).to eq(1)
    end
  end

  describe "#find_policy_for" do
    it "returns the named policy" do
      subject.populate do
        dispatch :foo
        to       { 'test@example.com' }
        whenever { true }
      end

      expect(subject.find_policy_for('Foo')).not_to be(nil)
    end
  end

  describe "#broadcast" do
    it "calls broadcast on each notification" do
      subject.populate do
        dispatch :foo
        to       { 'test@example.com' }
        whenever { true }
      end

      record = 'record'
      expect(subject.notifications[0]).to receive(:broadcast).with(record)
      subject.broadcast(record)
    end
  end

  describe "#dispatch" do
    it "saves new notifications" do
      subject.dispatch(:foo)
      expect(subject.notifications).not_to be(nil)
    end

    it "ignores existing notifications" do
      subject.dispatch(:foo)
      subject.dispatch(:foo)
      expect(subject.notifications.length).to eq(1)
    end
  end
end
