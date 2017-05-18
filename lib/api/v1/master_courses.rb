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

  def changed_asset_json(asset, action, locked, migration_id = nil, exceptions = {})
    asset_type = asset.class_name.underscore.sub(/^.+\//, '')
    url = case asset.class_name
    when 'Attachment'
      course_file_url(:course_id => asset.context.id, :id => asset.id)
    when 'Quizzes::Quiz'
      course_quiz_url(:course_id => asset.context.id, :id => asset.id)
    when 'AssessmentQuestionBank'
      course_question_bank_url(:course_id => asset.context.id, :id => asset.id)
    when 'ContextExternalTool'
      course_external_tool_url(:course_id => asset.context.id, :id => asset.id)
    when 'LearningOutcome'
      course_outcome_url(:course_id => asset.context.id, :id => asset.id)
    else
      polymorphic_url([asset.context, asset])
    end

    asset_name = if asset.respond_to?(:display_name)
      asset.display_name
    elsif asset.respond_to?(:title)
      asset.title
    else
      asset.name
    end

    json = {
      asset_id: asset.id,
      asset_type: asset_type,
      asset_name: asset_name,
      change_type: action.to_s,
      html_url: url,
      locked: locked
    }
    json[:exceptions] = exceptions[migration_id] || [] unless migration_id.nil?
    json
  end
end
