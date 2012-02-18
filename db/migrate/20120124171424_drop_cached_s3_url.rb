class DropCachedS3Url < ActiveRecord::Migration
  def self.up
    remove_column :attachments, :cached_s3_url
    remove_column :attachments, :s3_url_cached_at
  end

  def self.down
    add_column :attachments, :s3_url_cached_at, :datetime
    add_column :attachments, :cached_s3_url, :text
  end
end
