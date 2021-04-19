# frozen_string_literal: true

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
  include Api::V1::User

  def master_template_json(template, user, session, opts={})
    hash = api_json(template, user, session, :only => %w(id course_id), :methods => %w{last_export_completed_at associated_course_count})
    migration = template.active_migration
    hash[:latest_migration] = master_migration_json(migration, user, session) if migration
    hash
  end

  def master_migration_json(migration, user, session, opts={})
    migration.expire_if_necessary!
    hash = api_json(migration, user, session,
      :only => %w(id user_id workflow_state created_at exports_started_at imports_queued_at imports_completed_at comment))
    if opts[:subscription]
      hash['subscription_id'] = opts[:subscription].id
    else
      hash['template_id'] = migration.master_template_id
    end
    hash['id'] = opts[:child_migration].id if opts[:child_migration]
    hash['user'] = user_display_json(migration.user)
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
      course_outcome_url(:course_id => asset.context&.id || @course.id, :id => asset.id)
    when 'LearningOutcomeGroup'
      course_outcome_group_url(:course_id => asset.context.id, :id => asset.id)
    else
      polymorphic_url([asset.context, asset])
    end

    asset_name = Context.asset_name(asset)

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

  def changed_syllabus_json(course, exceptions=nil)
    {
      asset_id: course.id,
      asset_type: 'syllabus',
      asset_name: I18n.t('Syllabus'),
      change_type: :updated,
      html_url: syllabus_course_assignments_url(course),
      locked: false
    }.tap do |json|
      json[:exceptions] = exceptions['syllabus'] || [] if exceptions
    end
  end

  def changed_settings_json(course)
    {
      asset_id: course.id,
      asset_type: 'settings',
      asset_name: I18n.t('Course Settings'),
      change_type: :updated,
      html_url: course_settings_url(course),
      locked: false,
      exceptions: []
    }
  end

  def course_summary_json(course, opts={})
    can_read_sis = opts[:can_read_sis] || course.account.grants_any_right?(@current_user, :read_sis, :manage_sis)
    hash = api_json(course, @current_user, session, :only => %w{id name course_code})
    hash['sis_course_id'] = course.sis_source_id if can_read_sis
    hash['term_name'] = course.enrollment_term.name
    if opts[:include_teachers]
      if course.teacher_count
        hash['teacher_count'] = course.teacher_count
      else
        hash['teachers'] = course.teachers.map { |teacher| user_display_json(teacher) }
      end
    end
    hash
  end

  def child_subscription_json(sub)
    {
      id: sub.id,
      template_id: sub.master_template_id,
      blueprint_course: course_summary_json(sub.master_template.course)
    }
  end
end
