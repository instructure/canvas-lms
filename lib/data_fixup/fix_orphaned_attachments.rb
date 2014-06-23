module DataFixup
  class FixOrphanedAttachments

    def self.run
      @new_roots = Set.new
      Shackles.activate(:slave) do
        scope = Attachment.
          where('root_attachment_id IS NOT NULL AND
            NOT EXISTS (SELECT id
                        FROM attachments ra
                        WHERE ra.id = attachments.root_attachment_id)')
        create_users if scope.exists?
        scope.find_each(start: 0) do |a|
          next if @new_roots.include? a.root_attachment_id
          fix_orphaned_file(a)
          @new_roots << a.root_attachment_id
        end
      end
    end

    def self.create_users
      Shackles.activate(:master) do
        @deleted_user = User.create(name: 'rescued attachments')
        @deleted_user.destroy
        @broken_user = User.create(name: 'broken attachments')
        @broken_user.destroy
      end
    end

    def self.other_namespace(attachment)
      account_id = attachment.namespace.sub('account_', '').to_i
      if account_id.to_s.length > 8
        namespace_account_id = Account.find_by_id(account_id).try(:local_id)
      else
        namespace_account_id = attachment.shard.global_id_for(account_id)
      end
      "account_#{namespace_account_id}"
    end

    def self.s3_save(rescued_orphan, ns)
      if rescued_orphan.s3object.exists?
        rescued_orphan.save!
        rescued_orphan.namespace = ns
        finalize_attachment(rescued_orphan)
      else
        ns = rescued_orphan.namespace = other_namespace(rescued_orphan)
        if rescued_orphan.s3object.exists?
          rescued_orphan.save!
          rescued_orphan.namespace = ns
          finalize_attachment(rescued_orphan)
        else
          rescued_orphan.context_id = @broken_user.id
          finalize_attachment(rescued_orphan)
        end
      end
    end

    def self.local_storage_save(rescued_orphan)
      if File.exists? rescued_orphan.full_filename
        finalize_attachment(rescued_orphan)
      else
        rescued_orphan.context_id = @broken_user.id
        finalize_attachment(rescued_orphan)
      end
    end

    def self.finalize_attachment(attachment)
      attachment.file_state = 'deleted'
      attachment.save!
    end

    def self.fix_orphaned_file(attachment)
      rescued_orphan = Attachment.new
      rescued_orphan.id = attachment.root_attachment_id unless attachment.root_attachment_id > Shard::IDS_PER_SHARD
      rescued_orphan.context_type = 'User'
      rescued_orphan.context_id = @deleted_user.id
      rescued_orphan.size = attachment.size
      rescued_orphan.content_type = attachment.content_type
      rescued_orphan.filename = attachment.filename || "none"
      rescued_orphan.display_name = attachment.display_name
      rescued_orphan.file_state = 'deleted'
      rescued_orphan.md5 = attachment.md5
      ns = rescued_orphan.namespace = attachment.namespace
      Shackles.activate(:master) do
        Attachment.s3_storage? ? s3_save(rescued_orphan, ns) : local_storage_save(rescued_orphan)
        if rescued_orphan.id != attachment.root_attachment_id
          Attachment.where(root_attachment_id: attachment.root_attachment_id).update_all(root_attachment_id: rescued_orphan.id)
        end
      end
    end

  end
end
