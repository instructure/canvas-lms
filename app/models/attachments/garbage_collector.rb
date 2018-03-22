#
# Copyright (C) 2017 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

class Attachments::GarbageCollector
  class ByContextType
    attr_reader :context_type, :older_than, :restore_state, :dry_run, :stats
    def initialize(context_type:, older_than:, restore_state: 'processed', dry_run: false)
      @context_type = context_type
      @older_than = older_than
      @restore_state = restore_state
      @dry_run = dry_run
      @stats = Hash.new(0)
    end

    def delete_content
      to_delete_scope.where(root_attachment_id: nil).find_ids_in_batches(batch_size: 500) do |ids_batch|
        non_type_children = Attachment.where(root_attachment_id: ids_batch).
          not_deleted.
          where.not(context_type: context_type).
          where.not(root_attachment_id: nil). # postgres is being weird
          order([:root_attachment_id, :id]).
          select("distinct on (attachments.root_attachment_id) attachments.*").
          group_by(&:root_attachment_id)
        same_type_children_fields = Attachment.where(root_attachment_id: ids_batch).
          not_deleted.
          where(context_type: context_type).
          where.not(root_attachment_id: nil). # postgres is being weird
          select(:id, :created_at, :root_attachment_id).
          group_by(&:root_attachment_id)

        to_delete_ids = []
        Attachment.where(id: ids_batch).each do |att|
          same_type_children_ids = same_type_children_fields[att.id]&.map(&:id) || []
          same_type_children_max_created_at = same_type_children_fields[att.id]&.map(&:created_at)&.compact&.max

          if has_younger_children?(same_type_children_max_created_at)
            stats[:young_child] += 1
            next
          end

          if non_type_children[att.id].present?
            if context_type == 'ContentExport' &&
                non_type_children[att.id].detect{ |x| x.context_type == 'ContentMigration' }.present?
              stats[:cm_skipped] += 1
              next
            end

            stats[:reparent] += 1
            # make_childless separates this object and copies the content to
            # a new root attachment, so we still want to delete the content here.
            att.make_childless(non_type_children[att.id].first) unless dry_run
            destroy_att_with_retries(att)
          elsif att.filename.present?
            stats[:destroyed] += 1
            destroy_att_with_retries(att)
          end

          to_delete_ids.concat([att.id, same_type_children_ids].flatten)
        end

        if to_delete_ids.present?
          stats[:marked_deleted] += to_delete_ids.count
          updates = { workflow_state: 'deleted', file_state: 'deleted', deleted_at: Time.now.utc }
          Attachment.where(id: to_delete_ids).update_all(updates) unless dry_run
        end
      end
    end

    # Just in case this goes south: assumes versioning is enabled on the
    # bucket and old versions still exist (haven't been cleaned up by lifecycle
    # policies)
    def undelete_content
      raise "Only works with S3" unless Attachment.s3_storage?
      raise "Cannot delete rows in dry_run mode" if dry_run
      deleted_scope.where(root_attachment_id: nil).find_ids_in_batches do |ids_batch|
        restored = []
        Attachment.where(id: ids_batch).each do |att|
          versions = att.s3object.bucket.object_versions({prefix: att.s3object.key})
          delete_tokens, objects = versions.partition do |obj|
            obj.is_latest && obj.data.is_a?(Aws::S3::Types::DeleteMarkerEntry)
          end
          if objects.present? && delete_tokens.present?
            delete_tokens.each(&:delete)
            restored << att.id
          end
        end
        updates = { workflow_state: restore_state, file_state: 'available', deleted_at: nil, updated_at: Time.now.utc }
        Attachment.where(id: restored).update_all(updates) if restored.present?
      end
    end

    # Once you're confident and don't want to revert, clean up the DB rows
    def delete_rows
      raise "Cannot delete rows in dry_run mode" if dry_run
      while deleted_scope.where.not(:root_attachment_id => nil).limit(1000).delete_all > 0; end
      while deleted_scope.limit(1000).delete_all > 0; end
    end

    private

    def to_delete_scope
      scope = Attachment.where(context_type: context_type).
        where.not(file_state: 'deleted')
      scope = scope.where("created_at < ?", older_than) if older_than
      scope
    end

    def deleted_scope
      Attachment.where(
        context_type: context_type,
        workflow_state: 'deleted',
        file_state: 'deleted'
      )
    end

    def has_younger_children?(children_max_created_at)
      return false unless older_than
      return false unless children_max_created_at
      children_max_created_at >= older_than
    end

    def destroy_att_with_retries(att, tries = 3)
      att.destroy_content unless dry_run
    rescue Aws::S3::Errors::InternalError
      tries -= 1
      tries.zero? ? raise : (sleep(10) && retry)
    end
  end

  # context_type: 'Folder' is no longer generated by the code.
  # file exports now go through the content export flow.
  class FolderContextType < ByContextType
    def initialize(dry_run: false)
      super(context_type: 'Folder', older_than: nil, restore_state: 'zipped', dry_run: dry_run)
    end
  end

  # See the ContentExport model for a list of valid export types. Some, like
  # course copy, could be purged quickly, as they aren't user accessible.
  # Others, like QTI or Zip, can be downloaded by the user for a period of
  # time.  For now, we treat them all the same and just purge older than
  # a given date.
  #
  # NOTE: content_export.attachment are always either
  # - context_type='ContentExport', or
  # - context_type='User' (in the case of user data exports)
  # which is why we use the join conditions below
  class ContentExportContextType < ByContextType
    def initialize(older_than: ContentExport.expire_days.days.ago, dry_run: false)
      super(context_type: 'ContentExport', older_than: older_than, dry_run: dry_run)
    end

    def delete_rows
      raise "Cannot delete rows in dry_run mode" if dry_run
      null_scope = ContentExport.joins(<<-SQL).
INNER JOIN #{Attachment.quoted_table_name}
ON attachments.context_type = 'ContentExport'
AND content_exports.attachment_id = attachments.id
SQL
        where(attachments: { workflow_state: 'deleted', file_state: 'deleted' })
      while null_scope.limit(1000).update_all(attachment_id: nil) > 0; end
      super
    end
  end

  # We do lump exports and migrations together here because they are often
  # intertwined.
  #
  # NOTE: content_migration.attachment are always either
  # - context_type='ContentMigration', or
  # - context_type='ContentExport'
  class ContentExportAndMigrationContextType < ByContextType
    def initialize(older_than: ContentMigration.expire_days.days.ago, dry_run: false)
      super(context_type: ['ContentExport', 'ContentMigration'], older_than: older_than, dry_run: dry_run)
    end

    def delete_rows
      raise "Cannot delete rows in dry_run mode" if dry_run
      ce_null_scope = ContentExport.joins(<<-SQL).
INNER JOIN #{Attachment.quoted_table_name}
ON attachments.context_type = 'ContentExport'
AND content_exports.attachment_id = attachments.id
SQL
        where(attachments: { workflow_state: 'deleted', file_state: 'deleted' })
      while ce_null_scope.limit(1000).update_all(attachment_id: nil) > 0; end

      cm_null_scope = ContentMigration.joins(<<-SQL).
INNER JOIN #{Attachment.quoted_table_name}
ON attachments.context_type IN ('ContentMigration', 'ContentExport')
AND content_migrations.attachment_id = attachments.id
SQL
        where(attachments: { workflow_state: 'deleted', file_state: 'deleted' })
      while cm_null_scope.limit(1000).update_all(attachment_id: nil) > 0; end

      super
    end
  end
end
