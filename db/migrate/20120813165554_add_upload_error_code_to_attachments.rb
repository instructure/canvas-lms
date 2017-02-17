class AddUploadErrorCodeToAttachments < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :attachments, :upload_error_message, :string
  end

  def self.down
    remove_column :attachment, :upload_error_message
  end
end
