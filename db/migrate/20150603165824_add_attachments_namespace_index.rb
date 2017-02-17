class AddAttachmentsNamespaceIndex < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def change
    add_index :attachments, :namespace, algorithm: :concurrently
  end
end
