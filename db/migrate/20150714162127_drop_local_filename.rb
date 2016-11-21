class DropLocalFilename < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    remove_column :attachments, :local_filename
  end

  def down
    add_column :attachments, :local_filename, :string
  end
end
