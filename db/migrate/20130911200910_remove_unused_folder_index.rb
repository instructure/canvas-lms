class RemoveUnusedFolderIndex < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    remove_index :folders, name: "index_folders_on_parent_folder_id_and_workflow_state_and_name"
    remove_index :folders, name: "index_folders_on_parent_folder_id_and_workflow_state_an_position"
  end

  # no down; the original migration that added these was broken, so it was removed
end
