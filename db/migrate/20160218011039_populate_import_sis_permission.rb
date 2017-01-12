class PopulateImportSisPermission < ActiveRecord::Migration
  tag :predeploy

  def up
    DataFixup::AddRoleOverridesForNewPermission.run(:manage_sis, :import_sis)
  end

end
