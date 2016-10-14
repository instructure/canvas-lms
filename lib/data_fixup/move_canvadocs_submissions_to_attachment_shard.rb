module DataFixup::MoveCanvadocsSubmissionsToAttachmentShard
  def self.run
    CanvadocsSubmission.where(
      "crocodoc_document_id > ? OR canvadoc_id > ?",
      10**13, 10**13
    ).find_each do |cs|
      doc = CrocodocDocument.find(cs.crocodoc_document_id) ||
            Canvadoc.find(cs.canvadoc_id)
      doc.shard.activate do
        col = "#{doc.class_name.underscore}_id"
        CanvadocsSubmission.create submission_id: cs.submission.global_id,
          col => doc.id
      end
      cs.destroy
    end
  end
end
