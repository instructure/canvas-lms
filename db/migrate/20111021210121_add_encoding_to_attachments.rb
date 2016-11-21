class AddEncodingToAttachments < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :attachments, :encoding, :string
  end

  def self.down
    remove_column :attachments, :encoding
  end
end
