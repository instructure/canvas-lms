class AddNamspaceToThumbnail < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_column :thumbnails, :namespace, :string, null: true
  end
end
