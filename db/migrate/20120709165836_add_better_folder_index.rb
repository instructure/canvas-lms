class AddBetterFolderIndex < ActiveRecord::Migration
  tag :predeploy
  self.transactional = false

  def self.up
    if connection.adapter_name == 'PostgreSQL'
      if connection.select_value("SELECT COUNT(*) FROM pg_proc WHERE proname='collkey'").to_i != 0
        execute("CREATE INDEX CONCURRENTLY index_folders_on_parent_folder_id_and_workflow_state_and_name ON folders (parent_folder_id, workflow_state, collkey(name, 'root', true, 2, true))")
      else
        execute("CREATE INDEX CONCURRENTLY index_folders_on_parent_folder_id_and_workflow_state_and_name ON folders (parent_folder_id, workflow_state, CAST(LOWER(replace(name, '\\', '\\\\')) AS bytea))")
      end
    else
      add_index :folders, [:parent_folder_id, :workflow_state, :name], :name =>"index_folders_on_parent_folder_id_and_workflow_state_and_name", :length => { :name => 20 }
    end
    
    add_index :folders, [:parent_folder_id, :workflow_state, :position], :name =>"index_folders_on_parent_folder_id_and_workflow_state_an_position", :concurrently => true
    remove_index :folders, "index_folders_on_parent_folder_id"
  end

  def self.down
    add_index :folders, [:parent_folder_id], :name => "index_folders_on_parent_folder_id"
    remove_index :folders, "index_folders_on_parent_folder_id_and_workflow_state_and_name"
    remove_index :folders, "index_folders_on_parent_folder_id_and_workflow_state_an_position"
  end
end
