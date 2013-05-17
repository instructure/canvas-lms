class AddAssignmentDueDateOverrideNotifications < ActiveRecord::Migration
  tag :predeploy

  def self.up
    return unless Shard.current.default?
    Notification.create!(:name => "Assignment Due Date Override Changed", :category => "Due Date")
  end

  def self.down
    return unless Shard.current.default?
    Notification.find_by_name("Assignment Due Date Override Changed").try(:destroy)
  end
end
