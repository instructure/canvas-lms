class AddContextCodeIndexToSubmissions < ActiveRecord::Migration[5.1]
  tag :postdeploy
  disable_ddl_transaction!

  def change
    add_index :submissions, [:user_id, :context_code], :algorithm => :concurrently
  end
end
