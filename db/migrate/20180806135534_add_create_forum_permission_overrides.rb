class AddCreateForumPermissionOverrides < ActiveRecord::Migration[5.1]
  tag :predeploy

  def up
    DataFixup::AddRoleOverridesForNewPermission.run(:post_to_forum, :create_forum)
  end

  def down
  end
end
