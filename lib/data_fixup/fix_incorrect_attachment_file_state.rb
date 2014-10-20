module DataFixup::FixIncorrectAttachmentFileState
  def self.run
    while Attachment.where(file_state: 'active').limit(1000).update_all(file_state: 'available') > 0; end
  end
end
