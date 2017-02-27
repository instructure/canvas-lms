class ChangeUploadErrorMessageToText < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    change_column :attachments, :upload_error_message, :text
  end

  def down
    change_column :attachments, :upload_error_message, :string
  end
end
