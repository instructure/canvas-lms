class PopulateImportSisPermission < ActiveRecord::Migration[4.2]
  tag :predeploy

  def up
    DataFixup::AddRoleOverridesForNewPermission.run(:manage_sis, :import_sis)
  end

end
