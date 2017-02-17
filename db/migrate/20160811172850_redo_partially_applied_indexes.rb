class RedoPartiallyAppliedIndexes < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    if index_exists?(:attachments, [:folder_id, :file_state, :display_name], name: "index_attachments_on_folder_id_and_file_state_and_display_name2")
      remove_index "attachments", name: "index_attachments_on_folder_id_and_file_state_and_display_name2"
    end
  end
end
