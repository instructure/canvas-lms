class FixAttachmentSortingIndexes < ActiveRecord::Migration
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    if connection.adapter_name == 'PostgreSQL' && connection.select_value("SELECT 1 FROM pg_index WHERE indexrelid='index_attachments_on_folder_id_and_file_state_and_position'::regclass AND indpred IS NOT NULL")
      execute("ALTER INDEX index_attachments_on_folder_id_and_file_state_and_position RENAME TO index_attachments_on_folder_id_and_file_state_and_position2")
      add_index :attachments, [:folder_id, :file_state, :position], :algorithm => :concurrently
      remove_index :attachments, name: 'index_attachments_on_folder_id_and_file_state_and_position2'
    end
    remove_index :attachments, :folder_id
  end
end
