class AddAssignmentDueDateOverrideNotifications < ActiveRecord::Migration
  tag :predeploy

  def self.up
    return unless Shard.current.default?
    Notification.create!(:name => "Assignment Due Date Override Changed", :category => "Due Date")
  end

  def self.down
    return unless Shard.current.default?
    Notification.where(name: "Assignment Due Date Override Changed").delete_all
  end
end
