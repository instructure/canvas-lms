class IndexAttachmentsFindExistingRoot < ActiveRecord::Migration[5.2]
  tag :predeploy
  disable_ddl_transaction!

  def up
    add_index :attachments, [:md5, :namespace, :content_type], algorithm: :concurrently,
      where: "root_attachment_id IS NULL and filename IS NOT NULL"

  end

  def down
    remove_index :attachments, [:md5, :namespace, :content_type]
  end
end
