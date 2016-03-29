#
# Copyright (C) 2012 Instructure, Inc.
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

module Api::V1::ContentExport
  include Api::V1::User
  include Api::V1::Attachment

  def content_export_json(export, current_user, session)
    json = api_json(export, current_user, session, :only => %w(id user_id created_at workflow_state export_type))
    json['course_id'] = export.context_id if export.context_type == 'Course'
    if export.attachment && !export.for_course_copy?
      json[:attachment] = attachment_json(export.attachment, current_user, {}, {:can_view_hidden_files => true})
    end
    if export.job_progress
      json['progress_url'] = polymorphic_url([:api_v1, export.job_progress])
    end
    json
  end
end
