class AddQuizIdToAssignmentOverrides < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :assignment_overrides, :quiz_id, :integer, :limit => 8
    add_column :assignment_overrides, :quiz_version, :integer
    add_index :assignment_overrides, :quiz_id

    change_column :assignment_overrides, :assignment_id, :integer, :limit => 8, :null => true
    change_column :assignment_overrides, :assignment_version, :integer, :null => true
  end

  def self.down
    remove_index :assignment_overrides, :quiz_id
    remove_column :assignment_overrides, :quiz_id, :quiz_version

    change_column :assignment_overrides, :assignment_id, :integer, :limit => 8, :null => false
    change_column :assignment_overrides, :assignment_version, :integer, :null => false
  end
end
