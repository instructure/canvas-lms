class EscapeAttachmentFilenamesForS3 < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    DataFixup::EscapeS3Filenames.send_later_if_production(:run)
  end

  def self.down
  end
end
