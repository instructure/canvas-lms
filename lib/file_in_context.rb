# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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
#

# Attaches a file generally to another file, using the attachment_fu gateway.
class FileInContext
  class << self
    def queue_files_to_delete(queue = true)
      @queue_files_to_delete = queue
    end

    def destroy_queued_files
      if @queued_files.present?
        Attachment.delay_if_production.destroy_files(@queued_files.map(&:id))
        @queued_files.clear
      end
    end

    def destroy_files(files)
      if @queue_files_to_delete
        @queued_files ||= []
        @queued_files += files
      else
        files.each(&:destroy)
      end
    end

    def attach(context, filename, display_name: nil, folder: nil, explicit_filename: nil, allow_rename: false, md5: nil, migration_id: nil)
      display_name ||= File.split(filename).last

      if md5 && folder && !allow_rename
        scope = context.attachments.where(display_name:, folder:).not_deleted
        scope = scope.where(migration_id: [migration_id, nil]) if migration_id # either find a previous copy or an unassociated match
        existing_att = false

        # only engage in hash comparison if there are possible duplicates
        if scope.take
          existing_att = scope.where(md5:).take

          # Hashing an alternative digest to check the possible duplicate that didn't match the previous hash
          # Keep in mind that the md5 argument isn't necessarily an actual md5 hash, it may be a sha512 (maybe even other stuff in the future)
          unless existing_att
            alternative_digest = (md5.length == 32) ? Digest::SHA2.new(512).file(filename) : Digest::MD5.file(filename)
            scope = scope.where(md5: alternative_digest.hexdigest)
            existing_att = scope.take
          end
        end

        if existing_att
          if migration_id && existing_att.migration_id.nil? # can set an existing unassociated attachment to the new migration_id
            existing_att.update_attribute(:migration_id, migration_id)
          end
          return existing_att
        elsif migration_id
          allow_rename = true # prevent overwriting if there's an existing matching filename that has a different migration_id
        end
      end

      uploaded_data = Canvas::UploadedFile.new(filename, Attachment.mimetype(explicit_filename || filename))

      @attachment = Attachment.new(context:, display_name:, folder:)
      Attachments::Storage.store_for_attachment(@attachment, uploaded_data)
      @attachment.filename = explicit_filename if explicit_filename
      @attachment.migration_id = migration_id
      @attachment.set_publish_state_for_usage_rights
      @attachment.save!

      destroy_files(@attachment.handle_duplicates(allow_rename ? :rename : :overwrite, caller_will_destroy: true))

      @attachment
    ensure
      uploaded_data&.close
    end
  end
end
