class AddSubmissionsIndex < ActiveRecord::Migration
  tag :postdeploy
  disable_ddl_transaction!

  def change
    add_index :submissions, [:assignment_id, :user_id], algorithm: :concurrently
  end
end
