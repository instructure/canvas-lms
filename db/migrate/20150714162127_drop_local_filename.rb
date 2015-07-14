class DropLocalFilename < ActiveRecord::Migration
  tag :postdeploy

  def up
    remove_column :attachments, :local_filename
  end

  def down
    add_column :attachments, :local_filename, :string
  end
end
