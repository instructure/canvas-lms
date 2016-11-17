class AddMediaObjectsIndex < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def change
    add_index :media_objects, :root_account_id, algorithm: :concurrently
  end
end
