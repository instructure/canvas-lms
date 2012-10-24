class AssignmentOverrideIndexesMigration < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_index :assignment_overrides, [:set_type, :set_id]
    add_index :assignment_override_students, :user_id
  end

  def self.down
    remove_index :assignment_overrides, [:set_type, :set_id]
    remove_index :assignment_override_students, :user_id
  end
end
