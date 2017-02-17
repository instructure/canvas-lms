class FixPollingForeignKeys < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    change_column :polling_poll_submissions, :poll_session_id, :integer, limit: 8, null: false
    change_column :polling_polls, :user_id, :integer, limit: 8, null: false
  end

  def self.down
  end
end
