class AddOldMediaIdToMediaComments < ActiveRecord::Migration
  def self.up
    add_column :media_objects, :old_media_id, :string
    add_index :media_objects, [:old_media_id]
  end

  def self.down
    remove_column :media_objects, :old_media_id
  end
end
