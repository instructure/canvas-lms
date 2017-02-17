class DropZipFileImports < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def up
    drop_table :zip_file_imports if connection.table_exists?(:zip_file_imports)

    if Attachment.where(:context_type => "ZipFileImport").exists?
      Attachment.where(:context_type => "ZipFileImport").
        where("EXISTS (SELECT 1 FROM #{Attachment.quoted_table_name} child WHERE child.root_attachment_id=attachments.id AND child.context_type <> ?)", "ZipFileImport").
        readonly(false).find_each do |root|

        # move children attachments to a non-zipfileimport attachment
        child = Attachment.where(root_attachment_id: root).where.not(:context_type => "ZipFileImport").take
        child.root_attachment_id = nil
        child.filename ||= root.filename
        if Attachment.s3_storage?
          if root.s3object.exists? && !child.s3object.exists?
            root.s3object.copy_to(child.s3object)
          end
        else
          Attachment.where(:id => root).update_all(:content_type => "invalid/invalid") # prevents find_existing_attachment_for_md5 from reattaching the child to the old root
          child.uploaded_data = root.open
        end
        child.save!
        Attachment.where(root_attachment_id: root).where.not(:id => child).update_all(root_attachment_id: child)
      end
    end

    while Attachment.where(:context_type => "ZipFileImport").where.not(:root_attachment_id => nil).limit(1000).delete_all > 0; end
    while Attachment.where(:context_type => "ZipFileImport").limit(1000).delete_all > 0; end
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
