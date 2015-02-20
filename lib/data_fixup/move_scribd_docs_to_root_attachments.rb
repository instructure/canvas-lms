module DataFixup::MoveScribdDocsToRootAttachments
  def self.run
    env = Shackles.environment
    env = nil unless env == :deploy
    Shackles.activate(env || :slave) do
      Attachment.where("scribd_doc IS NOT NULL AND root_attachment_id IS NOT NULL").includes(:root_attachment).find_each do |a|
        ra = a.root_attachment
        # bad data!
        next unless ra

        # if the root doesn't have a scribd doc, move it over
        if !ra.scribd_doc
          ra.scribd_doc = a.scribd_doc
        else
          # otherwise, this is a dup, and we need to delete it
          Scribd::API.instance.user = a.scribd_user
          begin
            a.scribd_doc.destroy
          rescue Scribd::ResponseError => e
            # does not exist
            raise unless e.code == '612'
          end
        end
        # clear the scribd doc off the child
        a.scribd_doc = nil
        a.scribd_attempts = 0
        a.workflow_state = 'deleted'  # not file_state :P
        Shackles.activate(env || :master) do
          a.save!
          ra.save! if ra.changed?
        end
      end
    end
  end
end
