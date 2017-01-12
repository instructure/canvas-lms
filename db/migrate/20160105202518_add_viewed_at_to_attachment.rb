class AddViewedAtToAttachment < ActiveRecord::Migration
  tag :predeploy

  def change
    add_column :attachments, :viewed_at, :timestamp
  end
end
