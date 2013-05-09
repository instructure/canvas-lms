class LengthSubmissionAttachmentIds < ActiveRecord::Migration
  tag :predeploy

  def self.up
    change_column :submissions, :attachment_ids, :string, :limit => 4.kilobytes
  end

  def self.down
    change_column :submissions, :attachment_ids, :string, :limit => 255
  end
end
