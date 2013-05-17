class DestroyExistingAnonymousFolderDownloads < ActiveRecord::Migration
  def self.up
    # There was a bug allowing locked/hidden files to be downloaded in zip files for public
    # courses. This migration will delete those, so that no data leaks remain from the bug.
    Attachment.where(:context_type => 'Folder', :workflow_state => 'zipped', :user_id => nil).
        update_all(:workflow_state => 'deleted', :deleted_at => Time.zone.now)
  end

  def self.down
  end
end
