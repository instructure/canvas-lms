class AddStaleScribdIndexToAttachments < ActiveRecord::Migration
  tag :predeploy
  self.transactional = false

  def self.up
    add_index :attachments, [:last_inline_view, :created_at], conditions: "scribd_doc IS NOT NULL", concurrently: true
  end

  def self.down
    remove_index :attachments, [:last_inline_view, :created_at]
  end
end
