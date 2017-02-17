class AddSurveyFunctionalityToAccountNotifications < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :account_notifications, :required_account_service, :string
    add_column :account_notifications, :months_in_display_cycle, :int
    # this table is small enough for transactional index creation
    add_index :account_notifications, [:account_id, :end_at, :start_at], name: "index_account_notifications_by_account_and_timespan"
    remove_index :account_notifications, [:account_id, :start_at]
  end

  def self.down
    remove_column :account_notifications, :required_account_setting
    remove_column :account_notifications, :months_in_display_cycle
    add_index :account_notifications, [:account_id, :start_at]
    remove_index :account_notifications, name: "index_account_notifications_by_account_and_timespan"
  end
end
