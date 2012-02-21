class UseAssetUserAccessLastAccess < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    AssetUserAccess.update_all("last_access = updated_at", "last_access is null")
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
