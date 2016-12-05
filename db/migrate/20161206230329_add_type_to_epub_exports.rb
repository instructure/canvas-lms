class AddTypeToEpubExports < ActiveRecord::Migration
  tag :predeploy

  def change
    add_column :epub_exports, :type, :string, :limit => 255
  end
end
