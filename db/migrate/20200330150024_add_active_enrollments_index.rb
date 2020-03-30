class AddActiveEnrollmentsIndex < ActiveRecord::Migration[5.2]
  tag :postdeploy
  disable_ddl_transaction!

  def change
    add_index :enrollments, [:course_id], where: "workflow_state = 'active'",
      name: "index_enrollments_on_course_when_active", algorithm: :concurrently
  end
end
