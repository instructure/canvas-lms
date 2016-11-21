class PopulateManageCatalogPermission < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    DataFixup::AddRoleOverridesForNewPermission.send_later_if_production(:run, :manage_account_memberships, :manage_catalog)
  end

  def down
  end
end
