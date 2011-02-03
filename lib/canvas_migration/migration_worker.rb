#
# Copyright (C) 2011 Instructure, Inc.
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

require 'action_controller'
require 'action_controller/test_process.rb'

module Canvas::MigrationWorker
  def self.upload_overview_file(file, content_migration)
    uploaded_data = ActionController::TestUploadedFile.new(file.path, Attachment.mimetype(file.path))
    
    att = Attachment.new
    att.context = content_migration
    att.uploaded_data = uploaded_data
    att.save
    begin
      uploaded_data.unlink
    rescue
      Rails.logger.warn "Couldn't unlink overview for content_migration #{content_migration.id}"
    end
    content_migration.overview_attachment = att
    content_migration.save
    att
  end
end
