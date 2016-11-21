class AddSubmissionsIndex < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def change
    add_index :submissions, [:assignment_id, :user_id], algorithm: :concurrently
  end
end
