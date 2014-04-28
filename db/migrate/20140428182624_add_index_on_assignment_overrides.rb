class AddIndexOnAssignmentOverrides < ActiveRecord::Migration
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    add_index :assignment_overrides, :assignment_id, algorithm: :concurrently
  end

  def self.down
    remove_index :assignment_overrides, :assignment_id
  end
end
