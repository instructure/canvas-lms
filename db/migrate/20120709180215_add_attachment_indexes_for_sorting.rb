class AddAttachmentIndexesForSorting < ActiveRecord::Migration
  tag :predeploy
  self.transactional = false

  def self.up
    if connection.adapter_name == 'PostgreSQL'
      if connection.select_value("SELECT COUNT(*) FROM pg_proc WHERE proname='collkey'").to_i != 0
        execute("CREATE INDEX CONCURRENTLY index_attachments_on_folder_id_and_file_state_and_display_name ON attachments (folder_id, file_state, collkey(display_name, 'root', true, 2, true)) WHERE folder_id IS NOT NULL")
      else
        execute("CREATE INDEX CONCURRENTLY index_attachments_on_folder_id_and_file_state_and_display_name ON attachments (folder_id, file_state, CAST(LOWER(replace(display_name, '\\', '\\\\')) AS bytea)) WHERE folder_id IS NOT NULL")
      end
      execute("CREATE INDEX CONCURRENTLY index_attachments_on_folder_id_and_file_state_and_position ON attachments (folder_id, file_state, position) WHERE folder_id IS NOT NULL")
    else
      add_index :attachments, [:folder_id, :file_state, :display_name], :name =>"index_attachments_on_folder_id_and_file_state_and_display_name"
      add_index :attachments, [:folder_id, :file_state, :position], :name =>"index_attachments_on_folder_id_and_file_state_and_position"
    end
    
    remove_index :attachments, "index_attachments_on_folder_id"
  end

  def self.down
    add_index :attachments, [:folder_id], :name => "index_attachments_on_folder_id"
    remove_index :attachments, "index_attachments_on_folder_id_and_file_state_and_display_name"
    remove_index :attachments, "index_attachments_on_folder_id_and_file_state_and_position"
  end
end
