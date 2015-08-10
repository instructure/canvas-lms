class AddAttachmentIndexesForSorting < ActiveRecord::Migration
  tag :predeploy
  disable_ddl_transaction!

  def self.up
    if connection.adapter_name == 'PostgreSQL'
      concurrently = " CONCURRENTLY" if connection.open_transactions == 0
      if collkey = connection.extension_installed?(:pg_collkey)
        execute("CREATE INDEX#{concurrently} index_attachments_on_folder_id_and_file_state_and_display_name ON attachments (folder_id, file_state, #{collkey}.collkey(display_name, 'root', true, 2, true)) WHERE folder_id IS NOT NULL")
      else
        execute("CREATE INDEX#{concurrently} index_attachments_on_folder_id_and_file_state_and_display_name ON attachments (folder_id, file_state, CAST(LOWER(replace(display_name, '\\', '\\\\')) AS bytea)) WHERE folder_id IS NOT NULL")
      end
    else
      add_index :attachments, [:folder_id, :file_state, :display_name], :length => { :display_name => 20 }
    end
    add_index :attachments, [:folder_id, :file_state, :position], :algorithm => :concurrently

    remove_index :attachments, :folder_id
  end

  def self.down
    add_index :attachments, :folder_id, algorithm: :concurrently
    remove_index :attachments, "index_attachments_on_folder_id_and_file_state_and_display_name"
    remove_index :attachments, "index_attachments_on_folder_id_and_file_state_and_position"
  end
end
