class DropRedundantSubmissionsIndex < ActiveRecord::Migration
  tag :predeploy

  def self.up
    # there's also a (unique) index on [:user_id, :assignment_id]
    remove_index :submissions, [:user_id]
  end

  def self.down
    add_index :submissions, [:user_id]
  end
end
