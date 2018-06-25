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

module Canvas::LiveEvents
  def self.post_event_stringified(event_name, payload, context = nil)
    StringifyIds.recursively_stringify_ids(payload)
    StringifyIds.recursively_stringify_ids(context)
    LiveEvents.post_event(
      event_name: event_name,
      payload: payload,
      time: Time.zone.now,
      context: context
    )
  end

  def self.amended_context(canvas_context)
    ctx = LiveEvents.get_context || {}
    return ctx unless canvas_context
    ctx = ctx.merge({
      context_type: canvas_context.class.to_s,
      context_id: canvas_context.global_id
    })
    if canvas_context.respond_to?(:root_account)
      ctx.merge!({
        root_account_id: canvas_context.root_account.try(:global_id),
        root_account_uuid: canvas_context.root_account.try(:uuid),
        root_account_lti_guid: canvas_context.root_account.try(:lti_guid),
      })
    end
    ctx
  end

  def self.get_course_data(course)
    {
      course_id: course.global_id,
      uuid: course.uuid,
      account_id: course.global_account_id,
      name: course.name,
      created_at: course.created_at,
      updated_at: course.updated_at,
      workflow_state: course.workflow_state
    }
  end

  def self.course_created(course)
    post_event_stringified('course_created', get_course_data(course))
  end

  def self.course_updated(course)
    post_event_stringified('course_updated', get_course_data(course))
  end

  def self.course_syllabus_updated(course, old_syllabus_body)
    post_event_stringified('syllabus_updated', {
      course_id: course.global_id,
      syllabus_body: LiveEvents.truncate(course.syllabus_body),
      old_syllabus_body: LiveEvents.truncate(old_syllabus_body)
    })
  end

  def self.discussion_entry_created(entry)
    payload = {
      discussion_entry_id: entry.global_id,
      discussion_topic_id: entry.global_discussion_topic_id,
      text: LiveEvents.truncate(entry.message)
    }

    if entry.parent_id
      payload.merge!({
        parent_discussion_entry_id: entry.global_parent_id
      })
    end

    post_event_stringified('discussion_entry_created', payload)
  end

  def self.discussion_topic_created(topic)
    post_event_stringified('discussion_topic_created', {
      discussion_topic_id: topic.global_id,
      is_announcement: topic.is_announcement,
      title: LiveEvents.truncate(topic.title),
      body: LiveEvents.truncate(topic.message)
    })
  end

  def self.account_notification_created(notification)
    post_event_stringified('account_notification_created', {
      account_notification_id: notification.global_id,
      subject: LiveEvents.truncate(notification.subject),
      message: LiveEvents.truncate(notification.message),
      icon: notification.icon,
      start_at: notification.start_at,
      end_at: notification.end_at,
    })
  end

  def self.get_group_membership_data(membership)
    {
      group_membership_id: membership.global_id,
      user_id: membership.global_user_id,
      group_id: membership.global_group_id,
      group_name: membership.group.name,
      group_category_id: membership.group.global_group_category_id,
      group_category_name: membership.group.group_category.try(:name),
      workflow_state: membership.workflow_state
    }
  end

  def self.group_membership_created(membership)
    post_event_stringified('group_membership_created', get_group_membership_data(membership))
  end

  def self.group_membership_updated(membership)
    post_event_stringified('group_membership_updated', get_group_membership_data(membership))
  end

  def self.get_group_category_data(group_category)
    {
      group_category_id: group_category.global_id,
      group_category_name: group_category.name,
      context_id: group_category.context_id,
      context_type: group_category.context_type,
      group_limit: group_category.group_limit
    }
  end

  def self.group_category_updated(group_category)
    post_event_stringified('group_category_updated', get_group_category_data(group_category))
  end

  def self.group_category_created(group_category)
    post_event_stringified('group_category_created', get_group_category_data(group_category))
  end

  def self.get_group_data(group)
    {
      group_category_id: group.global_group_category_id,
      group_category_name: group.group_category.try(:name),
      group_id: group.global_id,
      uuid: group.uuid,
      group_name: group.name,
      context_type: group.context_type,
      context_id: group.global_context_id,
      account_id: group.global_account_id,
      workflow_state: group.workflow_state,
      max_membership: group.max_membership
    }
  end

  def self.group_created(group)
    post_event_stringified('group_created', get_group_data(group))
  end

  def self.group_updated(group)
    post_event_stringified('group_updated', get_group_data(group))
  end

  def self.get_assignment_data(assignment)
    {
      assignment_id: assignment.global_id,
      context_id: assignment.global_context_id,
      context_type: assignment.context_type,
      workflow_state: assignment.workflow_state,
      title: LiveEvents.truncate(assignment.title),
      description: LiveEvents.truncate(assignment.description),
      due_at: assignment.due_at,
      unlock_at: assignment.unlock_at,
      lock_at: assignment.lock_at,
      updated_at: assignment.updated_at,
      points_possible: assignment.points_possible,
      lti_assignment_id: assignment.lti_context_id,
      lti_resource_link_id: assignment.lti_resource_link_id,
      lti_resource_link_id_duplicated_from: assignment.duplicate_of&.lti_resource_link_id
    }
  end

  def self.assignment_created(assignment)
    post_event_stringified('assignment_created', get_assignment_data(assignment))
  end

  def self.assignment_updated(assignment)
    post_event_stringified('assignment_updated', get_assignment_data(assignment))
  end

  def self.get_submission_data(submission)
    {
      submission_id: submission.global_id,
      assignment_id: submission.global_assignment_id,
      user_id: submission.global_user_id,
      submitted_at: submission.submitted_at,
      lti_user_id: submission.lti_user_id,
      graded_at: submission.graded_at,
      updated_at: submission.updated_at,
      score: submission.score,
      grade: submission.grade,
      submission_type: submission.submission_type,
      body: LiveEvents.truncate(submission.body),
      url: submission.url,
      attempt: submission.attempt,
      lti_assignment_id: submission.assignment.lti_context_id,
      group_id: submission.group_id
    }
  end

  def self.get_attachment_data(attachment)
    {
      attachment_id: attachment.global_id,
      user_id: attachment.global_user_id,
      display_name: LiveEvents.truncate(attachment.display_name),
      filename: LiveEvents.truncate(attachment.filename),
      context_type: attachment.context_type,
      context_id: attachment.global_context_id,
      content_type: attachment.content_type,
      folder_id: attachment.global_folder_id,
      unlock_at: attachment.unlock_at,
      lock_at: attachment.lock_at,
      updated_at: attachment.updated_at
    }
  end

  def self.submission_created(submission)
    post_event_stringified('submission_created', get_submission_data(submission))
  end

  def self.submission_updated(submission)
    post_event_stringified('submission_updated', get_submission_data(submission))
  end

  def self.plagiarism_resubmit(submission)
    post_event_stringified('plagiarism_resubmit', get_submission_data(submission))
  end

  def self.get_user_data(user)
    {
      user_id: user.global_id,
      uuid: user.uuid,
      name: user.name,
      short_name: user.short_name,
      workflow_state: user.workflow_state,
      created_at: user.created_at,
      updated_at: user.updated_at
    }
  end

  def self.user_created(user)
    post_event_stringified('user_created', get_user_data(user))
  end

  def self.user_updated(user)
    post_event_stringified('user_updated', get_user_data(user))
  end

  def self.get_enrollment_data(enrollment)
    data = {
      enrollment_id: enrollment.global_id,
      course_id: enrollment.global_course_id,
      user_id: enrollment.global_user_id,
      user_name: enrollment.user_name,
      type: enrollment.type,
      created_at: enrollment.created_at,
      updated_at: enrollment.updated_at,
      limit_privileges_to_course_section: enrollment.limit_privileges_to_course_section,
      course_section_id: enrollment.global_course_section_id,
      workflow_state: enrollment.workflow_state
    }
    data[:associated_user_id] = enrollment.global_associated_user_id if enrollment.observer?
    data
  end

  def self.enrollment_created(enrollment)
    post_event_stringified('enrollment_created', get_enrollment_data(enrollment))
  end

  def self.enrollment_updated(enrollment)
    post_event_stringified('enrollment_updated', get_enrollment_data(enrollment))
  end

  def self.get_enrollment_state_data(enrollment_state)
    {

      enrollment_id: enrollment_state.global_enrollment_id,
      state: enrollment_state.state,
      state_started_at: enrollment_state.state_started_at,
      state_is_current: enrollment_state.state_is_current,
      state_valid_until: enrollment_state.state_valid_until,
      restricted_access: enrollment_state.restricted_access,
      access_is_current: enrollment_state.access_is_current
    }
  end

  def self.enrollment_state_created(enrollment_state)
    post_event_stringified('enrollment_state_created', get_enrollment_state_data(enrollment_state))
  end

  def self.enrollment_state_updated(enrollment_state)
    post_event_stringified('enrollment_state_updated', get_enrollment_state_data(enrollment_state))
  end

  def self.user_account_association_created(assoc)
    post_event_stringified('user_account_association_created', {
      user_id: assoc.global_user_id,
      account_id: assoc.global_account_id,
      account_uuid: assoc.account.uuid,
      created_at: assoc.created_at,
      updated_at: assoc.updated_at,
      is_admin: !(assoc.account.root_account.all_account_users_for(assoc.user).empty?),
    })
  end

  def self.logged_in(session, user, pseudonym)
    ctx = LiveEvents.get_context || {}
    ctx[:user_id] = user.global_id
    ctx[:user_login] = pseudonym.unique_id
    ctx[:user_account_id] = pseudonym.account.global_id
    ctx[:user_sis_id] = pseudonym.sis_user_id
    post_event_stringified('logged_in', {
      redirect_url: session[:return_to]
    }, ctx)
  end

  def self.logged_out
    post_event_stringified('logged_out', {})
  end

  def self.quiz_submitted(submission)
    # TODO: include score, for automatically graded portions?
    post_event_stringified('quiz_submitted', {
      submission_id: submission.global_id,
      quiz_id: submission.global_quiz_id
    })
  end

  def self.wiki_page_created(page)
    post_event_stringified('wiki_page_created', {
      wiki_page_id: page.global_id,
      title: LiveEvents.truncate(page.title),
      body: LiveEvents.truncate(page.body)
    })
  end

  def self.wiki_page_updated(page, old_title, old_body)
    payload = {
      wiki_page_id: page.global_id,
      title: LiveEvents.truncate(page.title),
      body: LiveEvents.truncate(page.body)
    }

    if old_title
      payload[:old_title] = LiveEvents.truncate(old_title)
    end

    if old_body
      payload[:old_body] = LiveEvents.truncate(old_body)
    end

    post_event_stringified('wiki_page_updated', payload)
  end

  def self.wiki_page_deleted(page)
    post_event_stringified('wiki_page_deleted', {
      wiki_page_id: page.global_id,
      title: LiveEvents.truncate(page.title)
    })
  end

  def self.attachment_created(attachment)
    post_event_stringified('attachment_created', get_attachment_data(attachment))
  end

  def self.attachment_updated(attachment, old_display_name)
    payload = get_attachment_data(attachment)
    if old_display_name
      payload[:old_display_name] = LiveEvents.truncate(old_display_name)
    end

    post_event_stringified('attachment_updated', payload)
  end

  def self.attachment_deleted(attachment)
    post_event_stringified('attachment_deleted', get_attachment_data(attachment))
  end

  def self.grade_changed(submission, old_submission=nil, old_assignment=submission.assignment)
    grader_id = nil
    if submission.grader_id && !submission.autograded?
      grader_id = submission.global_grader_id
    end

    sis_pseudonym = SisPseudonym.for(submission.user, submission.assignment.root_account, type: :trusted, require_sis: false)

    post_event_stringified('grade_change', {
      submission_id: submission.global_id,
      assignment_id: submission.global_assignment_id,
      grade: submission.grade,
      old_grade: old_submission.try(:grade),
      score: submission.score,
      old_score: old_submission.try(:score),
      points_possible: submission.assignment.points_possible,
      old_points_possible: old_assignment.points_possible,
      grader_id: grader_id,
      student_id: submission.global_user_id,
      student_sis_id: sis_pseudonym&.sis_user_id,
      user_id: submission.global_user_id,
      grading_complete: submission.graded?,
      muted: submission.muted_assignment?
    }, amended_context(submission.assignment.context))
  end

  def self.asset_access(asset, category, role, level)
    asset_subtype = nil
    if asset.is_a?(Array)
      asset_subtype = asset[0]
      asset_obj = asset[1]
    else
      asset_obj = asset
    end

    post_event_stringified('asset_accessed', {
      asset_type: asset_obj.class.reflection_type_name,
      asset_id: asset_obj.global_id,
      asset_subtype: asset_subtype,
      category: category,
      role: role,
      level: level
    })
  end

  def self.quiz_export_complete(content_export)
    payload = content_export.settings[:quizzes2]
    post_event_stringified('quiz_export_complete', payload, amended_context(content_export.context))
  end

  def self.content_migration_completed(content_migration)
    post_event_stringified(
      'content_migration_completed',
      content_migration_data(content_migration),
      amended_context(content_migration.context)
    )
  end

  def self.content_migration_data(content_migration)
    context = content_migration.context
    import_quizzes_next =
      content_migration.migration_settings&.[](:import_quizzes_next) == true
    {
      content_migration_id: content_migration.global_id,
      context_id: context.global_id,
      context_type: context.class.to_s,
      lti_context_id: context.lti_context_id,
      context_uuid: context.uuid,
      import_quizzes_next: import_quizzes_next
    }
  end

  def self.course_section_created(section)
    post_event_stringified('course_section_created', get_course_section_data(section))
  end

  def self.course_section_updated(section)
    post_event_stringified('course_section_updated', get_course_section_data(section))
  end

  def self.quizzes_next_quiz_duplicated(payload)
    post_event_stringified('quizzes_next_quiz_duplicated', payload)
  end

  def self.get_course_section_data(section)
    {
      course_section_id: section.id,
      sis_source_id: section.sis_source_id,
      sis_batch_id: section.sis_batch_id,
      course_id: section.course_id,
      root_account_id: section.root_account_id,
      enrollment_term_id: section.enrollment_term_id,
      name: section.name,
      default_section: section.default_section,
      accepting_enrollments: section.accepting_enrollments,
      can_manually_enroll: section.can_manually_enroll,
      start_at: section.start_at,
      end_at: section.end_at,
      workflow_state: section.workflow_state,
      restrict_enrollments_to_section_dates: section.restrict_enrollments_to_section_dates,
      nonxlist_course_id: section.nonxlist_course_id,
      stuck_sis_fields: section.stuck_sis_fields,
      integration_id: section.integration_id
    }
  end

  def self.module_created(context_module)
    post_event_stringified('module_created', get_context_module_data(context_module))
  end

  def self.module_updated(context_module)
    post_event_stringified('module_updated', get_context_module_data(context_module))
  end

  def self.get_context_module_data(context_module)
    {
      module_id: context_module.id,
      context_id: context_module.context_id,
      context_type: context_module.context_type,
      name: context_module.name,
      position: context_module.position,
      workflow_state: context_module.workflow_state
    }
  end

  def self.module_item_created(context_module_item)
    post_event_stringified('module_item_created', get_context_module_item_data(context_module_item))
  end

  def self.module_item_updated(context_module_item)
    post_event_stringified('module_item_updated', get_context_module_item_data(context_module_item))
  end

  def self.get_context_module_item_data(context_module_item)
    {
      module_item_id: context_module_item.id,
      module_id: context_module_item.context_module_id,
      context_id: context_module_item.context_id,
      context_type: context_module_item.context_type,
      position: context_module_item.position,
      workflow_state: context_module_item.workflow_state
    }
  end
end
