class AddQuizIdToAssignmentOverrideStudents < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :assignment_override_students, :quiz_id, :integer, :limit => 8
    add_index :assignment_override_students, :quiz_id
    change_column :assignment_override_students, :assignment_id, :integer, :limit => 8, :null => true
  end

  def self.down
    remove_column :assignment_override_students, :quiz_id
    remove_index :assignment_override_students, :quiz_id
    change_column :assignment_override_students, :assignment_id, :integer, :limit => 8, :null => false
  end
end
