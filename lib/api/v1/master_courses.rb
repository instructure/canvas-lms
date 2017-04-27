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

module Api::V1::MasterCourses
  def master_template_json(template, user, session, opts={})
    api_json(template, user, session, :only => %w(id course_id), :methods => %w{last_export_completed_at})
  end

  def master_migration_json(migration, user, session, opts={})
    hash = api_json(migration, user, session,
      :only => %w(id user_id workflow_state created_at exports_started_at imports_queued_at imports_completed_at comment))
    hash['template_id'] = migration.master_template_id
    hash
  end
end
