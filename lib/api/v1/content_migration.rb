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
  include Api::V1::Attachment

  def content_migrations_json(migrations, current_user, session)
    migrations.reject{|m| !!m.migration_settings['hide_from_index']}.map do |migration|
      content_migration_json(migration, current_user, session)
    end
  end

  def content_migration_json(migration, current_user, session, attachment_preflight=nil)
    json = api_json(migration, current_user, session, :only => %w(id user_id workflow_state started_at finished_at migration_type))
    json[:created_at] = migration.created_at
    if json[:workflow_state] == 'created'
      json[:workflow_state] = 'pre_processing'
    elsif json[:workflow_state] == 'pre_process_error'
      json[:workflow_state] = 'failed'
    elsif json[:workflow_state] == 'exported' && !migration.import_immediately?
      json[:workflow_state] = 'waiting_for_select'
    elsif ['exporting', 'importing', 'exported'].member?(json[:workflow_state])
      json[:workflow_state] = 'running'
    elsif json[:workflow_state] == 'imported'
      json[:workflow_state] = 'completed'
    end
    json[:migration_issues_url] = api_v1_course_content_migration_migration_issue_list_url(migration.context_id, migration.id)
    json[:migration_issues_count] = migration.migration_issues.count
    if attachment_preflight
      json[:pre_attachment] = attachment_preflight
    elsif migration.attachment && !migration.for_course_copy?
      json[:attachment] = attachment_json(migration.attachment, current_user, {}, {:can_view_hidden_files => true})
    end

    if migration.for_course_copy?
      if source = migration.source_course || (migration.migration_settings[:source_course_id] && Course.find(migration.migration_settings[:source_course_id]))
        json[:settings] = {}
        json[:settings][:source_course_id] = source.id
        json[:settings][:source_course_name] = source.name
        json[:settings][:source_course_html_url] = course_url(source.id)
      end
    end

    if migration.job_progress
      json['progress_url'] = polymorphic_url([:api_v1, migration.job_progress])
    end
    if plugin = Canvas::Plugin.find(migration.migration_type)
      if plugin.meta[:display_name] && plugin.meta[:display_name].respond_to?(:call)
        json['migration_type_title'] = plugin.meta[:display_name].call
      elsif plugin.meta[:name] && plugin.meta[:name].respond_to?(:call)
        json['migration_type_title'] = plugin.meta[:name].call
      end
    end

    # For easier auditing for support requests
    if Account.site_admin.grants_right?(current_user, :manage_courses)
      json[:audit_info] = migration.respond_to?(:slice) &&
                          migration.slice(:id,
                                          :user_id,
                                          :migration_settings,
                                          :started_at,
                                          :finished_at,
                                          :created_at,
                                          :updated_at,
                                          :progress,
                                          :context_type,
                                          :source_course_id,
                                          :migration_type)
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
