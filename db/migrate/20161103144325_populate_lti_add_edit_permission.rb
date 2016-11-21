class PopulateLtiAddEditPermission < ActiveRecord::Migration
  tag :postdeploy

  def change
    DataFixup::AddRoleOverridesForNewPermission.run(:manage_content, :lti_add_edit)
  end
end
