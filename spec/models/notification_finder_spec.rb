require_relative "../spec_helper"

describe NotificationFinder do
  let(:notification){ Notification.create!(name: "test notification")}
  let(:finder){ NotificationFinder.new([notification])}

  describe "#find_by_name and #by_name" do
    it 'finds a notification by name' do
      expect(finder.find_by_name(notification.name)).to eq(notification)
      expect(finder.by_name(notification.name)).to eq(notification)
    end

    it 'loads notifications from the cache' do
      expect(finder.notifications.length).to eq(1)
      Notification.expects(:connection).never
      finder.by_name(notification.name)
      finder.find_by_name(notification.name)
    end

    it 'freezes notifications so they cannot be modified' do
      expect(finder.find_by_name(notification.name).frozen?).to be(true)
    end
  end

  describe "#reset_cache" do
    it 'empties the cache' do
      expect(finder.notifications.count).to eq(1)
      finder.reset_cache
      expect(finder.notifications.count).to eq(0)
    end
  end
end
