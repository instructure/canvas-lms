class RemoveMultipleRootFolders < ActiveRecord::Migration
  tag :postdeploy
  self.transactional = false

  def self.up
    DataFixup::RemoveMultipleRootFolders.run
    if connection.adapter_name =~ /\Apostgresql/i
      execute("CREATE UNIQUE INDEX CONCURRENTLY index_folders_on_context_id_and_context_type_for_root_folders ON folders(context_id, context_type) WHERE parent_folder_id IS NULL AND workflow_state != 'deleted'")
    end
  end

  def self.down
    if connection.adapter_name =~ /\Apostgresql/i
      execute("DROP INDEX IF EXISTS index_folders_on_context_id_and_context_type_for_root_folders")
    end
  end
end
