class RemoveForeignKeyConstraintFromPollSessions < ActiveRecord::Migration
  tag :predeploy

  def self.up
    remove_foreign_key :polling_poll_sessions, column: :poll_id
  end

  def self.down
    add_foreign_key :polling_poll_sessions, :polling_polls, column: :poll_id
  end
end
