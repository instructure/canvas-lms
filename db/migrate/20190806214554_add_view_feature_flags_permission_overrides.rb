# frozen_string_literal: true

class AddViewFeatureFlagsPermissionOverrides < ActiveRecord::Migration[5.2]
  tag :predeploy

  def up
    DataFixup::AddRoleOverridesForNewPermission.run(:manage_feature_flags, :view_feature_flags)
  end

  def down
  end
end
