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
#

module GoogleDocsPreview
  PREVIEWABLE_TYPES = %w{
    application/vnd.openxmlformats-officedocument.wordprocessingml.template
    application/vnd.oasis.opendocument.spreadsheet
    application/vnd.sun.xml.writer
    application/excel
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
    text/rtf
    text/plain
    application/vnd.openxmlformats-officedocument.spreadsheetml.template
    application/vnd.sun.xml.impress
    application/vnd.sun.xml.calc
    application/vnd.ms-excel
    application/msword
    application/mspowerpoint
    application/rtf
    application/vnd.oasis.opendocument.presentation
    application/vnd.oasis.opendocument.text
    application/vnd.openxmlformats-officedocument.presentationml.template
    application/vnd.openxmlformats-officedocument.presentationml.slideshow
    application/vnd.openxmlformats-officedocument.presentationml.presentation
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
    application/postscript
    application/pdf
    application/vnd.ms-powerpoint
  }.freeze

  def self.previewable?(account, attachment)
    account&.service_enabled?(:google_docs_previews) &&
    PREVIEWABLE_TYPES.include?(attachment.content_type) &&
    attachment.downloadable?
  end

  def self.url_for(attachment)
    expires_in = Setting.get('google_docs_previews.link_duration_minutes', '5').to_i.minutes
    attachment.public_url(expires_in: expires_in)
  end
end
