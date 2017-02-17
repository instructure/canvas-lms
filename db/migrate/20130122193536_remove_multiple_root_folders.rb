class RemoveMultipleRootFolders < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    DataFixup::RemoveMultipleRootFolders.run
    if connection.adapter_name =~ /\Apostgresql/i
      add_index :folders, [:context_id, :context_type], :unique => true, :name => 'index_folders_on_context_id_and_context_type_for_root_folders', :algorithm => :concurrently, :where => "parent_folder_id IS NULL AND workflow_state<>'deleted'"
    end
  end

  def self.down
    if connection.adapter_name =~ /\Apostgresql/i
      remove_index :folders, name: 'index_folders_on_context_id_and_context_type_for_root_folders'
    end
  end
end
