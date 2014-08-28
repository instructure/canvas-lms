class AddThumbnailUuid < ActiveRecord::Migration
  class Thumbnail < ActiveRecord::Base; end

  def self.up
    add_column :thumbnails, :uuid, :string
    add_index :thumbnails, [:id, :uuid]

    Thumbnail.find_each do |t|
      t.uuid ||= CanvasSlug.generate_securish_uuid
      t.save
    end
  end

  def self.down
    remove_column :thumbnails, :uuid
  end
end
