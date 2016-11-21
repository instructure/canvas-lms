class AddFolderAndPositionIndexToAttachments < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def change
    add_index :attachments, [:folder_id, :position], algorithm: :concurrently, where: 'folder_id IS NOT NULL'
  end
end
