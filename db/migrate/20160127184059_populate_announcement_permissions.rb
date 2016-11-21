class PopulateAnnouncementPermissions < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    DataFixup::AddRoleOverridesForNewPermission.send_later_if_production(:run, :read_forum, :read_announcements)
  end

  def down
  end
end
