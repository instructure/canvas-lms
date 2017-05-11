#
# Copyright (C) 2012 - present Instructure, Inc.
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

module DataFixup::EscapeS3Filenames
  def self.run
    return unless Attachment.s3_storage?

    Attachment.class_eval do
      def copy_and_rename_with_escaping
        old_filename = filename
        new_filename = URI.escape(old_filename, /[\[\]"]/)

        Rails.logger.info "copying #{self.id} #{old_filename} to #{new_filename}"
        begin
          # Copy, not rename. For several reasons. We can clean up later.
          Attachment.bucket.object(File.join(base_path, old_filename)).copy_to(File.join(base_path, new_filename),
          :acl => attachment_options[:s3_access])

          # We're not going to call filename= here, because it will escape it again. That's right - calling
          # attachment.filename = attachment.filename is not safe. That's sucky but it's already always been
          # that way and will not be addressed by this commit.
          write_attribute(:filename, new_filename)
          save!
        rescue => e
          Rails.logger.info "  copy failed with #{e}"
        end
      end
    end

    # A more efficient query could be done using a regular expression, but this should be db agnostic
    Attachment.active.where("filename LIKE '%[%' or filename like '%]%' or filename like '%\"%'").find_in_batches do |batch|
      batch.each do |attachment|
        # Be paranoid...
        next unless attachment.filename =~ /[\[\]"]/
        attachment.copy_and_rename_with_escaping
      end
    end
  end
end