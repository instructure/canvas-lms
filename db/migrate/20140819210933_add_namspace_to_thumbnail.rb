class AddNamspaceToThumbnail < ActiveRecord::Migration
  tag :predeploy

  def change
    add_column :thumbnails, :namespace, :string, null: true
  end
end
