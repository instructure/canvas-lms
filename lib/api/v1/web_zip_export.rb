#
# Copyright (C) 2016 Instructure, Inc.
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

module Api::V1::WebZipExport
  include Api::V1::Attachment

  def web_zip_export_json(web_zip_export)
    api_json(web_zip_export, @current_user, session) do |attrs|
      attrs.progress_id = web_zip_export.job_progress.id
      attrs.progress_url = polymorphic_url([:api_v1, web_zip_export.job_progress])

      if web_zip_export.zip_attachment.present?
        attrs[:zip_attachment] = attachment_json(web_zip_export.zip_attachment, @current_user, {}, {
          can_view_hidden_files: true
        })
      end
    end
  end
end