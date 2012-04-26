class AddAssignmentLock < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :assignments, :freeze_on_copy, :boolean
    add_column :assignments, :copied, :boolean
  end

  def self.down
    remove_column :assignments, :freeze_on_copy
    remove_column :assignments, :copied
  end
end
