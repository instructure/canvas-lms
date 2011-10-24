class ScheduleAttachmentEncodingDetection < ActiveRecord::Migration
  def self.up
    Attachment.transaction do
      Attachment.find_each(:conditions => "encoding IS NULL AND content_type LIKE '%text%'") do |a|
        a.send_later_if_production(:infer_encoding)
      end
    end
  end

  def self.down
  end
end
