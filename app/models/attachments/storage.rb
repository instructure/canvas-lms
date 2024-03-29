# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

class Attachments::Storage
  def self.store_for_attachment(attachment, data)
    if InstFS.enabled?
      attachment.filename ||= detect_filename(data)
      instfs_uuid = InstFS.direct_upload(
        file_object: data,
        file_name: attachment.display_name.presence || attachment.filename || "attachment"
      )
      attachment.instfs_uuid = instfs_uuid
      attachment.md5 = Digest::SHA2.new(512).file(data).hexdigest if digest_file? data

      # populate attachment fields if they were not already set
      attachment.size ||= data.size
      attachment.content_type ||= attachment.detect_mimetype(data)
      attachment.workflow_state = "processed"
    else
      attachment.uploaded_data = data
    end
    data
  end

  def self.digest_file?(data)
    File.file? data
  rescue TypeError
    false
  end

  def self.detect_filename(data)
    if data.respond_to?(:original_filename)
      data.original_filename
    elsif data.respond_to?(:filename)
      data.filename
    elsif data.instance_of?(File)
      File.basename(data)
    end
  end
end
