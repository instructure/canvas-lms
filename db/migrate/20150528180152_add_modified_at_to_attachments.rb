class AddModifiedAtToAttachments < ActiveRecord::Migration
  tag :predeploy
  def change
    add_column :attachments, :modified_at, :datetime
  end
end
