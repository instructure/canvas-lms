class AddTypeToEpubExports < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_column :epub_exports, :type, :string, :limit => 255
  end
end
