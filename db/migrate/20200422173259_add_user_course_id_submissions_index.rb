class AddUserCourseIdSubmissionsIndex < ActiveRecord::Migration[5.2]
  tag :predeploy
  disable_ddl_transaction!

  def change
    add_index :submissions, [:user_id, :course_id], :algorithm => :concurrently
  end
end
