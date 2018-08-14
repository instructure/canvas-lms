class AddIndexToAssignmentOverrideStudentsOnQuiz < ActiveRecord::Migration[5.1]
  tag :postdeploy
  disable_ddl_transaction!

  def change
    add_index :assignment_override_students, [:user_id, :quiz_id], :algorithm => :concurrently
  end
end
