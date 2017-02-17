class AddOldMediaIdToMediaComments < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :media_objects, :old_media_id, :string
    add_index :media_objects, [:old_media_id]
  end

  def self.down
    remove_column :media_objects, :old_media_id
  end
end
