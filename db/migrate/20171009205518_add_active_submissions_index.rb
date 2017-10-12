class AddActiveSubmissionsIndex < ActiveRecord::Migration[5.0]
  tag :postdeploy
  disable_ddl_transaction!

  def change
    add_index :submissions, [:assignment_id, :grading_period_id],
              algorithm: :concurrently,
              name: 'index_active_submissions',
              where: "workflow_state <> 'deleted'"
  end
end
