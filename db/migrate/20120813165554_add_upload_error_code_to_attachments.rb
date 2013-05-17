class AddUploadErrorCodeToAttachments < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :attachments, :upload_error_message, :string
  end

  def self.down
    remove_column :attachment, :upload_error_message
  end
end
