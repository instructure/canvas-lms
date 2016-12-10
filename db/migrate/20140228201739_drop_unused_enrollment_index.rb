class DropUnusedEnrollmentIndex < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    remove_index :enrollments, [:root_account_id]
  end

  def self.down
    add_index :enrollments, [:root_account_id], algorithm: :concurrently
  end
end
