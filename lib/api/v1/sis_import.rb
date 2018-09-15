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

module Api::V1::SisImport
  include Api::V1::Json
  include Api::V1::Attachment
  include Api::V1::User
  include Api::V1::SisImportError

  def sis_imports_json(batches, user, session)
    SisBatch.load_downloadable_attachments(batches)
    batches.map do |f|
      sis_import_json(f, user, session)
    end
  end

  def sis_import_json(batch, user, session, includes: [])
    json = api_json(batch, user, session)
    if batch.errors_attachment_id
      # skip permission checks since the context is a sis_import it will fail permission checks
      json[:errors_attachment] = attachment_json(
        batch.errors_attachment,
        user,
        {},
        # skip permission checks since the context is a sis_import it will fail permission checks
        {skip_permission_checks: true}
      )
    end
    json[:user] = user_json(batch.user, user, session) if batch.user
    atts = batch.downloadable_attachments
    json[:csv_attachments] = attachments_json(atts, user, {}, {skip_permission_checks: true}) if atts.any?
    json
  end
end
