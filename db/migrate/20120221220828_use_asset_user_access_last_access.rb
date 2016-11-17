class UseAssetUserAccessLastAccess < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    DataFixup::UseAssetUserAccessLastAccess.send_later_if_production(:run)
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
