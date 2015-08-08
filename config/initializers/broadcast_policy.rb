require 'broadcast_policy'
BroadcastPolicy.notifier = lambda { Notifier.new }
BroadcastPolicy.notification_finder = lambda { NotificationFinder.new(Notification.all_cached) }
ActiveRecord::Base.send(:extend, BroadcastPolicy::ClassMethods)
