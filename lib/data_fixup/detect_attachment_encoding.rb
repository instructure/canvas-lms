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

module DataFixup::DetectAttachmentEncoding
  def self.run
    begin
      attachments = Attachment.where("encoding IS NULL AND content_type LIKE '%text%'").limit(5000).to_a
      attachments.each do |a|
        begin
          a.infer_encoding
        rescue
          # some old attachments may have been cleaned off disk, but not out of the db
          Rails.logger.warn "Unable to detect encoding for attachment #{a.id}: #{$!}"
          Attachment.where(:id => a).update_all(:encoding => '')
        end
      end
    end until attachments.empty?
  end
end