require 'broadcast_policy'
Rails.configuration.to_prepare do
  BroadcastPolicy.notifier = lambda { Notifier.new }
  BroadcastPolicy.notification_finder = lambda { NotificationFinder.new(Notification.all_cached) }
end
ActiveRecord::Base.send(:extend, BroadcastPolicy::ClassMethods)
