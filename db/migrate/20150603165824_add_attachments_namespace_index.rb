class AddAttachmentsNamespaceIndex < ActiveRecord::Migration
  tag :postdeploy
  disable_ddl_transaction!

  def change
    add_index :attachments, :namespace, algorithm: :concurrently
  end
end
