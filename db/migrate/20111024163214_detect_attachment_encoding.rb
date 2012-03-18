class DetectAttachmentEncoding < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    DataFixup::DetectAttachmentEncoding.send_later_if_production(:run)
  end

  def self.down
  end
end
