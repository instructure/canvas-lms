class AddIndexOnEnrollments < ActiveRecord::Migration
  tag :postdeploy
  disable_ddl_transaction!

  def change
    add_index :enrollments, [:course_id, :user_id], algorithm: :concurrently
  end
end
