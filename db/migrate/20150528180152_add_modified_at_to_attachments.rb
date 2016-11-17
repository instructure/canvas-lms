class AddModifiedAtToAttachments < ActiveRecord::Migration[4.2]
  tag :predeploy
  def change
    add_column :attachments, :modified_at, :datetime
  end
end
