class AddPriorityToNotification < ActiveRecord::Migration[5.2]
  tag :predeploy

  PRIORITY_MESSAGE_LIST = ["Account User Registration",
                           "Confirm Email Communication Channel",
                           "Confirm Registration",
                           "Confirm SMS Communication Channel",
                           "Enrollment Invitation",
                           "Enrollment Notification",
                           "Forgot Password",
                           "Manually Created Access Token Created",
                           "Merge Email Communication Channel",
                           "Pseudonym Registration",
                           "Pseudonym Registration Done",
                           "Self Enrollment Registration"].freeze

  # Generally we don't want to add a default to a new column, but we know this
  # is a very small table and it is ok
  def change
    add_column :notifications, :priority, :boolean, default: false, null: false
    Notification.where(name: PRIORITY_MESSAGE_LIST).update_all(priority: true) if Shard.current.default?
  end
end
