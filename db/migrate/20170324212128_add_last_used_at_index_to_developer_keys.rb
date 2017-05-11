class AddLastUsedAtIndexToDeveloperKeys < ActiveRecord::Migration[4.2]
  tag :predeploy
  disable_ddl_transaction!

  def change
    add_index :access_tokens, [:developer_key_id, :last_used_at], algorithm: :concurrently
  end
end
