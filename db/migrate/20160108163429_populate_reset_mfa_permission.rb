class PopulateResetMfaPermission < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    DataFixup::AddRoleOverridesForNewPermission.send_later_if_production(:run, :manage_account_memberships, :reset_any_mfa)
  end

  def down
  end
end
