class AddIndexOnSubmissionsSubmittedAt < ActiveRecord::Migration
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    add_index :submissions, :submitted_at, algorithm: :concurrently
  end

  def self.down
    remove_index :submissions, :submitted_at
  end
end
