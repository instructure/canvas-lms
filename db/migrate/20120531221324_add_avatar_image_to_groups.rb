class AddAvatarImageToGroups < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :groups, :avatar_attachment_id, :integer, :limit => 8
  end

  def self.down
    remove_column :groups, :avatar_attachment_id
  end
end
