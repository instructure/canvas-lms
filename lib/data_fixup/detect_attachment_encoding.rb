module DataFixup::DetectAttachmentEncoding
  def self.run
    begin
      attachments = Attachment.where("encoding IS NULL AND content_type LIKE '%text%'").limit(5000).to_a
      attachments.each do |a|
        begin
          a.infer_encoding
        rescue
          # some old attachments may have been cleaned off disk, but not out of the db
          Rails.logger.warn "Unable to detect encoding for attachment #{a.id}: #{$!}"
          Attachment.where(:id => a).update_all(:encoding => '')
        end
      end
    end until attachments.empty?
  end
end