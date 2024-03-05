# frozen_string_literal: true

class AddPriorityToNotification < ActiveRecord::Migration[5.2]
  tag :predeploy

  def runnable?
    Shard.current.default?
  end

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

  def change
    Notification.where(name: PRIORITY_MESSAGE_LIST).update_all(priority: true)
  end
end
