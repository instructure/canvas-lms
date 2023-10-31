# frozen_string_literal: true

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
    class << self
      def delete_content(...)
        new(...).delete_content
      end

      def delete_rows(...)
        new(...).delete_rows
      end
    end

    attr_reader :context_type, :older_than, :restore_state, :stats

    def initialize(context_type:, older_than:, restore_state: "processed")
      @context_type = context_type
      @older_than = older_than
      @restore_state = restore_state
      @stats = Hash.new(0)
    end

    def delete_content
      loop do
        to_delete = to_delete_scope.limit(500).to_a
        break if to_delete.empty?

        non_type_children = Attachment.where(root_attachment: to_delete)
                                      .not_deleted
                                      .where.not(context_type:)
                                      .where.not(root_attachment_id: nil) # postgres is being weird
                                      .order([:root_attachment_id, :id])
                                      .group_by(&:root_attachment_id)
        same_type_children = Attachment.where(root_attachment: to_delete)
                                       .not_deleted
                                       .where(context_type:)
                                       .where.not(root_attachment_id: nil) # postgres is being weird
                                       .group_by(&:root_attachment_id)

        to_delete_ids = []
        to_break_ids = []
        Parallel.each(to_delete, in_threads: 10) do |att|
          younger_same_type_children = younger_children(same_type_children[att.id] || [])
          older_same_type_children = (same_type_children[att.id] || []) - younger_same_type_children

          if non_type_children[att.id].present? || younger_same_type_children.present?
            to_orphan = (non_type_children[att.id] || []) + younger_same_type_children
            stats[:reparent] += to_orphan.length
            # make_childless separates this object and copies the content to
            # a new root attachment, so we still want to delete the content here.
            to_orphan.each do |child_att|
              att.make_childless(child_att)
            end
          elsif att.filename.present?
            stats[:destroyed] += 1
          end
          destroy_att_with_retries(att)

          to_delete_ids.concat([att.id, older_same_type_children.map(&:id)].flatten)
        rescue => e
          Canvas::Errors.capture_exception(:attachment_garbage_collector, e)
          to_break_ids << att.id
        end

        unless to_delete_ids.empty?
          stats[:marked_deleted] += to_delete_ids.count
          updates = { workflow_state: "deleted", file_state: "deleted", deleted_at: Time.now.utc }
          Attachment.where(id: to_delete_ids).update_all(updates)
        end

        next if to_break_ids.empty?

        stats[:marked_broken] += to_delete_ids.count
        updates = { workflow_state: "deleted", file_state: "broken", deleted_at: Time.now.utc }
        Attachment.where(id: to_break_ids).update_all(updates)
      end
    end

    # Once you're confident and don't want to revert, clean up the DB rows
    def delete_rows
      deleted_scope.where.not(root_attachment_id: nil).in_batches.delete_all
      deleted_scope.in_batches.delete_all
    end

    private

    def to_delete_scope
      scope = Attachment.where(root_attachment_id: nil, context_type:)
                        .where.not(file_state: ["deleted", "broken"]).order(:created_at)
      if Array.wrap(context_type).include?("ContentExport")
        scope = scope.where.not("EXISTS (
          SELECT 1
          FROM #{ContentExport.quoted_table_name}
          INNER JOIN #{ContentShare.quoted_table_name} ON content_shares.content_export_id = content_exports.id
          WHERE content_exports.attachment_id = attachments.id
        )")
      end
      scope = scope.where("created_at < ?", older_than) if older_than
      scope
    end

    def deleted_scope
      Attachment.where(
        context_type:,
        workflow_state: "deleted",
        file_state: "deleted"
      )
    end

    def younger_children(children)
      return [] unless older_than

      children.select { |c| c.created_at >= older_than }
    end

    def destroy_att_with_retries(att, tries = 3)
      att.destroy_content
    rescue Aws::S3::Errors::InternalError
      tries -= 1
      tries.zero? ? raise : (sleep(10) && retry)
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
    def initialize(older_than: ContentExport.expire_days.days.ago)
      super(context_type: "ContentExport", older_than:)
    end

    def delete_rows
      null_scope = ContentExport.joins(<<~SQL.squish)
        INNER JOIN #{Attachment.quoted_table_name}
        ON attachments.context_type = 'ContentExport'
        AND content_exports.attachment_id = attachments.id

      SQL
                                .where(attachments: { workflow_state: "deleted", file_state: "deleted" })
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
    def initialize(older_than: ContentMigration.expire_days.days.ago)
      super(context_type: ["ContentExport", "ContentMigration"], older_than:)
    end

    def delete_rows
      ce_null_scope = ContentExport.joins(<<~SQL.squish)
        INNER JOIN #{Attachment.quoted_table_name}
        ON attachments.context_type = 'ContentExport'
        AND content_exports.attachment_id = attachments.id
      SQL
                                   .where(attachments: { workflow_state: "deleted", file_state: "deleted" })
      while ce_null_scope.limit(1000).update_all(attachment_id: nil) > 0; end

      cm_null_scope = ContentMigration.joins(<<~SQL.squish)
        INNER JOIN #{Attachment.quoted_table_name}
        ON attachments.context_type IN ('ContentMigration', 'ContentExport')
        AND content_migrations.attachment_id = attachments.id
      SQL
                                      .where(attachments: { workflow_state: "deleted", file_state: "deleted" })
      while cm_null_scope.limit(1000).update_all(attachment_id: nil) > 0; end

      cm_null_scope = ContentMigration.joins(<<~SQL.squish)
        INNER JOIN #{Attachment.quoted_table_name}
        ON attachments.context_type IN ('ContentMigration', 'ContentExport')
        AND content_migrations.overview_attachment_id = attachments.id
      SQL
                                      .where(attachments: { workflow_state: "deleted", file_state: "deleted" })
      while cm_null_scope.limit(1000).update_all(overview_attachment_id: nil) > 0; end

      cm_null_scope = ContentMigration.joins(<<~SQL.squish)
        INNER JOIN #{Attachment.quoted_table_name}
        ON attachments.context_type IN ('ContentMigration', 'ContentExport')
        AND content_migrations.exported_attachment_id = attachments.id
      SQL
                                      .where(attachments: { workflow_state: "deleted", file_state: "deleted" })
      while cm_null_scope.limit(1000).update_all(exported_attachment_id: nil) > 0; end

      cm_null_scope = ContentMigration.joins(<<~SQL.squish)
        INNER JOIN #{Attachment.quoted_table_name}
        ON attachments.context_type IN ('ContentMigration', 'ContentExport')
        AND content_migrations.asset_map_attachment_id = attachments.id
      SQL
                                      .where(attachments: { workflow_state: "deleted", file_state: "deleted" })
      while cm_null_scope.limit(1000).update_all(asset_map_attachment_id: nil) > 0; end

      super
    end
  end
end
