class DropZipFileImports < ActiveRecord::Migration
  tag :postdeploy

  def up
    while Attachment.where(:context_type => "ZipFileImport").limit(1000).delete_all > 0; end
    drop_table :zip_file_imports
  end

  def down
    create_table :zip_file_imports do |t|
      t.string    :workflow_state, :null => false
      t.datetime  :created_at
      t.datetime  :updated_at
      t.integer   :context_id, :limit => 8, :null => false
      t.string    :context_type, :null => false
      t.integer   :attachment_id, :limit => 8
      t.integer   :folder_id, :limit => 8
      t.float     :progress
      t.text      :data
    end
    add_index :zip_file_imports, :attachment_id, algorithm: :concurrently
  end
end
