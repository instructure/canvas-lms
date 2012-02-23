class EscapeAttachmentFilenamesForS3 < ActiveRecord::Migration
  def self.up
    DataFixup::EscapeS3Filenames.send_later_if_production(:run)
  end

  def self.down
  end
end
