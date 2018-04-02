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
      instfs_uuid = InstFS.direct_upload(
        file_object: data,
        file_name: attachment.display_name
      )
      attachment.instfs_uuid = instfs_uuid

      # populate attachment fields if they were not already set
      attachment.size ||= data.size
      attachment.filename ||= detect_filename(data)
      attachment.content_type ||= detect_mimetype(data)
    else
      attachment.uploaded_data = data
    end
    data
  end

  def self.detect_filename(data)
    if data.respond_to?(:original_filename)
      data.original_filename
    elsif data.respond_to?(:filename)
      data.filename
    elsif data.class == File
      File.basename(data)
    end
  end

  def self.detect_mimetype(data)
    if data && data.respond_to?(:content_type) && (data.content_type.blank? || data.content_type.strip == "application/octet-stream")
      res = nil
      res ||= File.mime_type?(data.original_filename) if data.respond_to?(:original_filename)
      res ||= File.mime_type?(data)
      res ||= "text/plain" unless data.respond_to?(:path)
      res || 'unknown/unknown'
    elsif data.respond_to?(:content_type)
      data.content_type
    else
      'unknown/unknown'
    end
  end
end
