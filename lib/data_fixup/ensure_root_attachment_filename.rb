module DataFixup::EnsureRootAttachmentFilename
  def self.run
    Shackles.activate(:slave) do
      Attachment.where(root_attachment_id: nil).
        joins("INNER JOIN #{Attachment.quoted_table_name} child ON attachments.id = child.root_attachment_id AND attachments.filename <> child.filename").
        where.not(workflow_state: 'broken').find_each do |root|
        unless root.s3object.exists?
          try_children root
        end
      end
      Attachment.where.not(root_attachment_id: nil, filename: nil, workflow_state: 'broken').find_in_batches do |batch|
        Shackles.activate(:master) do
          Attachment.where(id: batch).update_all(filename: nil)
        end
      end
    end
  end

  def self.try_children(root)
    root.children.where.not(filename: nil).where.not(filename: root.filename).each do |child|
      if child.s3object.exists?
        Shackles.activate(:master) do
          root.update_attribute(:filename, child.filename)
        end
        return true
      end
    end
  end
end
