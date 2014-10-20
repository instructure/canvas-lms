class MockNotificationFinder
  def initialize(notifications)
    @notifications = notifications
  end

  def find_by_name(notification_name)
    @notifications[notification_name]
  end

  def by_name(name)
    find_by_name(name)
  end
end
