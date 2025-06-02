# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

class AttachmentAssociationsSpecHelper
  def self.create_attachments_and_html(account, course)
    account.root_account.enable_feature!(:file_association_access)
    att = course.attachments.create!(uploaded_data: Rack::Test::UploadedFile.new("spec/fixtures/files/docs/doc.doc", "application/msword", true))
    [
      att,
      "<p>Here is a link to a file: <a href=\"/courses/#{course.id}/files/#{att.id}/download\">doc.doc</a></p>"
    ]
  end
end
