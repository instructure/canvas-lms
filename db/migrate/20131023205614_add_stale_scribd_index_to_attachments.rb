class AddStaleScribdIndexToAttachments < ActiveRecord::Migration[4.2]
  tag :predeploy
  disable_ddl_transaction!

  def self.up
    add_index :attachments, [:last_inline_view, :created_at], where: "scribd_doc IS NOT NULL", algorithm: :concurrently
  end

  def self.down
    remove_index :attachments, [:last_inline_view, :created_at]
  end
end
