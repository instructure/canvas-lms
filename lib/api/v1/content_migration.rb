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

module Api::V1::ContentMigration
  include Api::V1::Json

  def content_migrations_json(migrations, current_user, session)
    migrations.map do |migration|
      content_migration_json(migration, current_user, session)
    end
  end

  def content_migration_json(migration, current_user, session)
    json = api_json(migration, current_user, session, :only => %w(id user_id workflow_state started_at finished_at))
    json[:workflow_state] = 'converting' if json[:workflow_state] == 'exporting'
    json[:workflow_state] = 'converted' if json[:workflow_state] == 'exported'
    json[:migration_issues_url] = api_v1_course_content_migration_migration_issue_list_url(migration.context_id, migration.id)
    json[:migration_issues_count] = migration.migration_issues.count
    if migration.attachment
      json[:content_archive_download_url] = api_v1_course_content_migration_download_url(migration.context_id, migration.id)
    end
    json
  end

  def migration_issues_json(issues, migration, current_user, session)
    issues.map do |issue|
      migration_issue_json(issue, migration, current_user, session)
    end
  end

  def migration_issue_json(issue, migration, current_user, session)
    json = api_json(issue, current_user, session, :only => %w(id description workflow_state fix_issue_html_url issue_type created_at updated_at))
    json[:content_migration_url] = api_v1_course_content_migration_url(migration.context_id, issue.content_migration_id)
    if issue.grants_right?(current_user, :read_errors)
      json[:error_message] = issue.error_message
      json[:error_report_html_url] = error_url(issue.error_report_id) if issue.error_report_id
    end

    json
  end
end
