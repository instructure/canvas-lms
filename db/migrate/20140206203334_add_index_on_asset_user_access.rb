class AddIndexOnAssetUserAccess < ActiveRecord::Migration
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    add_index :asset_user_accesses, [:context_id, :context_type, :user_id, :updated_at],
              name: 'index_asset_user_accesses_on_ci_ct_ui_ua', algorithm: :concurrently
    remove_index :asset_user_accesses, [:context_id, :context_type]
  end

  def self.down
    add_index :asset_user_accesses, [:context_id, :context_type], algorithm: :concurrently
    remove_index :asset_user_accesses, name: 'index_asset_user_accesses_on_ci_ct_ui_ua'
  end
end
