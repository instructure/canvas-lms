# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

module Api::V1::EpubExport
  include Api::V1::Attachment

  def course_epub_export_json(course)
    api_json(course, @current_user, session, {
      only: [ :name, :id ]
    }) do |attrs|
      if course.latest_epub_export.present?
        attrs.epub_export = epub_export_json(course.latest_epub_export)
      end
    end
  end

  def epub_export_json(epub_export)
    api_json(epub_export, @current_user, session, {}, [
      :download, :regenerate
    ]) do |attrs|
      attrs.progress_id = epub_export.job_progress.id
      attrs.progress_url = polymorphic_url([:api_v1, epub_export.job_progress])

      [ :epub_attachment, :zip_attachment ].each do |attachment_type|
        if epub_export.send(attachment_type).present?
          attrs[attachment_type] = attachment_json(epub_export.send(attachment_type), @current_user, {}, {
            can_view_hidden_files: true
          })
        end
      end
    end
  end
end
