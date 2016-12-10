class AddReplacementAttachmentIdToAttachments < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :attachments, :replacement_attachment_id, :integer, :limit => 8
    add_foreign_key :attachments, :attachments, :column => :replacement_attachment_id, :delay_validation => true
  end

  def self.down
    remove_foreign_key :attachments, :column => :replacement_attachment_id
    remove_column :attachments, :replacement_attachment_id
  end
end
