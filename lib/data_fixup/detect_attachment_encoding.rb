module DataFixup::DetectAttachmentEncoding
  def self.run
    begin
      attachments = Attachment.find(:all, :conditions => "encoding IS NULL AND content_type LIKE '%text%'", :limit => 5000)
      attachments.each do |a|
        begin
          a.infer_encoding
        rescue
          # some old attachments may have been cleaned off disk, but not out of the db
          Rails.logger.warn "Unable to detect encoding for attachment #{a.id}: #{$!}"
          Attachment.update_all({:encoding => ''}, {:id => a.id})
        end
      end
    end until attachments.empty?
  end
end