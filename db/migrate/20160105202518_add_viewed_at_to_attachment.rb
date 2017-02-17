class AddViewedAtToAttachment < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_column :attachments, :viewed_at, :timestamp
  end
end
