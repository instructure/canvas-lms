# frozen_string_literal: true

class MakeAccountNotificationUsersNotNull < ActiveRecord::Migration[5.1]
  tag :postdeploy

  def change
    change_column_null :account_notifications, :user_id, false
  end
end
