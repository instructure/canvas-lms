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
  class FolderExports
    def self.delete_content
      max_id = 0
      root_scope.find_ids_in_batches(batch_size: 500) do |ids_batch|
        non_folder_children = Attachment.where(root_attachment_id: ids_batch).
          where.not(root_attachment_id: nil). # postgres is being weird
          where.not(context_type: 'Folder').
          order([:root_attachment_id, :id]).
          select("distinct on (attachments.root_attachment_id) attachments.*").
          group_by(&:root_attachment_id)
        folder_children_ids = Attachment.where(root_attachment_id: ids_batch).
          where(context_type: 'Folder').
          pluck(:id)

        Attachment.where(id: ids_batch).each do |att|
          if non_folder_children[att.id].present?
            att.make_childless(non_folder_children[att.id].first)
          elsif att.filename.present?
            att.destroy_content
          end

          max_id = [max_id, att.id, folder_children_ids].flatten.max
        end
      end

      update_scope = Attachment.where(context_type: 'Folder').
        where("id <= ?", max_id).
        where.not(workflow_state: 'deleted', file_state: 'deleted')
      updates = { workflow_state: 'deleted', file_state: 'deleted', deleted_at: Time.now.utc }
      while update_scope.limit(1000).update_all(updates) > 0; end
    end

    # Just in case this goes south: assumes versioning is enabled on the
    # bucket and old versions still exist (haven't been cleaned up by lifecycle
    # policies)
    def self.undelete_content
      raise "Only works with S3" unless Attachment.s3_storage?
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
        updates = { workflow_state: 'zipped', file_state: 'available', deleted_at: nil, updated_at: Time.now.utc }
        Attachment.where(id: restored).update_all(updates) if restored.present?
      end
    end

    # Once you're confident and don't want to revert, clean up the DB rows
    def self.delete_rows
      while deleted_scope.where.not(:root_attachment_id => nil).limit(1000).delete_all > 0; end
      while deleted_scope.limit(1000).delete_all > 0; end
    end

    def self.root_scope
      Attachment.where(context_type: 'Folder', root_attachment_id: nil).where.not(file_state: 'deleted')
    end

    def self.deleted_scope
      Attachment.where(context_type: 'Folder', workflow_state: 'deleted', file_state: 'deleted')
    end
  end
end
