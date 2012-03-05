class UseAssetUserAccessLastAccess < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    DataFixup::UseAssetUserAccessLastAccess.send_later_if_production(:run)
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
