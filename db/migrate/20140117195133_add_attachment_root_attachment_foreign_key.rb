class AddAttachmentRootAttachmentForeignKey < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    DataFixup::FixOrphanedAttachments.run
    add_foreign_key :attachments, :attachments, column: :root_attachment_id, delay_validation: true
  end

  def self.down
    remove_foreign_key :attachments, column: :root_attachment_id
  end
end
