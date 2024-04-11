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

module Canvas::LiveEvents
  def self.post_event_stringified(event_name, payload, context = nil)
    ctx = LiveEvents.get_context || {}
    payload.compact! if ctx[:compact_live_events].present?

    StringifyIds.recursively_stringify_ids(payload)
    StringifyIds.recursively_stringify_ids(context)
    LiveEvents.post_event(
      event_name:,
      payload:,
      time: Time.zone.now,
      context:
    )
  end

  def self.base_context_attributes(canvas_context, root_account)
    res = {}

    if canvas_context
      res[:context_type] = canvas_context.class.to_s
      res[:context_id] = canvas_context.global_id
      res[:context_account_id] = Context.get_account_or_parent_account_global_id(canvas_context)
      if canvas_context.respond_to?(:sis_source_id)
        res[:context_sis_source_id] = canvas_context.sis_source_id
      end
    end

    if root_account
      res[:root_account_uuid] = root_account&.uuid
      res[:root_account_id] = root_account&.global_id
      res[:root_account_lti_guid] = root_account&.lti_guid
    end

    res
  end

  def self.amended_context(canvas_context)
    (LiveEvents.get_context || {}).merge(
      base_context_attributes(canvas_context, canvas_context.try(:root_account))
    )
  end

  def self.conversation_created(conversation)
    post_event_stringified("conversation_created", {
                             conversation_id: conversation.id,
                             updated_at: conversation.updated_at
                           })
  end

  def self.conversation_forwarded(conversation)
    post_event_stringified("conversation_forwarded",
                           {
                             conversation_id: conversation.id,
                             updated_at: conversation.updated_at
                           },
                           amended_context(nil))
  end

  def self.get_course_data(course)
    {
      course_id: course.global_id,
      uuid: course.uuid,
      account_id: course.global_account_id,
      account_uuid: course.account.uuid,
      name: course.name,
      created_at: course.created_at,
      updated_at: course.updated_at,
      workflow_state: course.workflow_state
    }
  end

  def self.course_created(course)
    post_event_stringified("course_created", get_course_data(course))
  end

  def self.course_updated(course)
    post_event_stringified("course_updated", get_course_data(course))
  end

  def self.course_syllabus_updated(course, old_syllabus_body)
    post_event_stringified("syllabus_updated", {
                             course_id: course.global_id,
                             syllabus_body: LiveEvents.truncate(course.syllabus_body),
                             old_syllabus_body: LiveEvents.truncate(old_syllabus_body)
                           })
  end

  def self.conversation_message_created(conversation_message)
    post_event_stringified("conversation_message_created", {
                             author_id: conversation_message.author_id,
                             conversation_id: conversation_message.conversation_id,
                             created_at: conversation_message.created_at,
                             message_id: conversation_message.id
                           })
  end

  def self.discussion_entry_created(entry)
    post_event_stringified("discussion_entry_created", get_discussion_entry_data(entry))
  end

  def self.discussion_entry_submitted(entry, assignment_id, submission_id)
    payload = get_discussion_entry_data(entry)
    payload[:assignment_id] = assignment_id unless assignment_id.nil?
    payload[:submission_id] = submission_id unless submission_id.nil?
    post_event_stringified("discussion_entry_submitted", payload)
  end

  def self.get_discussion_entry_data(entry)
    payload = {
      user_id: entry.user_id,
      created_at: entry.created_at,
      discussion_entry_id: entry.id,
      discussion_topic_id: entry.discussion_topic_id,
      text: LiveEvents.truncate(entry.message)
    }

    payload[:parent_discussion_entry_id] = entry.parent_id if entry.parent_id
    payload
  end

  def self.discussion_topic_created(topic)
    post_event_stringified("discussion_topic_created", get_discussion_topic_data(topic))
  end

  def self.discussion_topic_updated(topic)
    post_event_stringified("discussion_topic_updated", get_discussion_topic_data(topic))
  end

  def self.get_discussion_topic_data(topic)
    {
      discussion_topic_id: topic.global_id,
      is_announcement: topic.is_announcement,
      title: LiveEvents.truncate(topic.title),
      body: LiveEvents.truncate(topic.message),
      assignment_id: topic.assignment_id,
      context_id: topic.context_id,
      context_type: topic.context_type,
      workflow_state: topic.workflow_state,
      lock_at: topic.lock_at,
      updated_at: topic.updated_at
    }
  end

  def self.account_notification_created(notification)
    post_event_stringified("account_notification_created", {
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
    post_event_stringified("group_membership_created", get_group_membership_data(membership))
  end

  def self.group_membership_updated(membership)
    post_event_stringified("group_membership_updated", get_group_membership_data(membership))
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
    post_event_stringified("group_category_updated", get_group_category_data(group_category))
  end

  def self.group_category_created(group_category)
    post_event_stringified("group_category_created", get_group_category_data(group_category))
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
    post_event_stringified("group_created", get_group_data(group))
  end

  def self.group_updated(group)
    post_event_stringified("group_updated", get_group_data(group))
  end

  def self.get_assignment_data(assignment)
    created_on_blueprint_sync =
      MasterCourses::ChildSubscription.is_child_course?(assignment.context) &&
      assignment.migration_id&.start_with?(MasterCourses::MIGRATION_ID_PREFIX)

    event = {
      anonymous_grading: assignment.anonymous_grading,
      assignment_group_id: assignment.global_assignment_group_id,
      assignment_id: assignment.global_id,
      assignment_id_duplicated_from: assignment.duplicate_of&.global_id&.to_s,
      context_id: assignment.global_context_id,
      context_type: assignment.context_type,
      context_uuid: assignment.context.uuid,
      created_on_blueprint_sync: created_on_blueprint_sync || false,
      description: LiveEvents.truncate(assignment.description),
      due_at: assignment.due_at,
      lti_assignment_description: LiveEvents.truncate(assignment.description),
      lti_assignment_id: assignment.lti_context_id,
      lti_resource_link_id: assignment.lti_resource_link_id,
      lti_resource_link_id_duplicated_from: assignment.duplicate_of&.lti_resource_link_id,
      lock_at: assignment.lock_at,
      points_possible: assignment.points_possible,
      resource_map: assignment.resource_map,
      submission_types: assignment.submission_types,
      title: LiveEvents.truncate(assignment.title),
      unlock_at: assignment.unlock_at,
      updated_at: assignment.updated_at,
      workflow_state: assignment.workflow_state
    }

    actl = assignment.assignment_configuration_tool_lookups.take
    domain = assignment.root_account&.environment_specific_domain
    event[:domain] = domain if domain
    original_domain = assignment.duplicate_of&.root_account&.environment_specific_domain
    event[:domain_duplicated_from] = original_domain if original_domain
    if actl && (tool_proxy = Lti::ToolProxy.proxies_in_order_by_codes(
      context: assignment.course,
      vendor_code: actl.tool_vendor_code,
      product_code: actl.tool_product_code,
      resource_type_code: actl.tool_resource_type_code
    ).first)
      event[:associated_integration_id] = tool_proxy.guid
    end
    event
  end

  def self.assignment_created(assignment)
    post_event_stringified("assignment_created", get_assignment_data(assignment))
  end

  def self.assignment_updated(assignment)
    post_event_stringified("assignment_updated", get_assignment_data(assignment))
  end

  def self.assignment_group_created(assignment_group)
    post_event_stringified("assignment_group_created", get_assignment_group_data(assignment_group))
  end

  def self.assignment_group_updated(assignment_group)
    post_event_stringified("assignment_group_updated", get_assignment_group_data(assignment_group))
  end

  def self.get_assignment_group_data(assignment_group)
    {
      assignment_group_id: assignment_group.id,
      context_id: assignment_group.context_id,
      context_type: assignment_group.context_type,
      name: assignment_group.name,
      position: assignment_group.position,
      group_weight: assignment_group.group_weight,
      sis_source_id: assignment_group.sis_source_id,
      integration_data: assignment_group.integration_data,
      rules: assignment_group.rules,
      workflow_state: assignment_group.workflow_state
    }
  end

  def self.assignments_bulk_updated(assignment_ids)
    Assignment.where(id: assignment_ids).find_each { |a| assignment_updated(a) }
  end

  def self.submissions_bulk_updated(submissions)
    Submission.where(id: submissions).preload(:assignment).find_each { |submission| submission_updated(submission) }
  end

  def self.attachments_bulk_deleted(attachment_ids)
    Attachment.where(id: attachment_ids).find_each { |a| attachment_deleted(a) }
  end

  def self.users_bulk_updated(user_ids)
    User.where(id: user_ids).find_each { |u| user_updated(u) }
  end

  def self.get_assignment_override_data(override)
    data_hash = {
      assignment_override_id: override.id,
      assignment_id: override.assignment_id,
      due_at: override.due_at,
      all_day: override.all_day,
      all_day_date: override.all_day_date,
      unlock_at: override.unlock_at,
      lock_at: override.lock_at,
      type: override.set_type,
      workflow_state: override.workflow_state,
    }

    case override.set_type
    when "CourseSection"
      data_hash[:course_section_id] = override.set_id
    when "Group"
      data_hash[:group_id] = override.set_id
    end

    data_hash
  end

  def self.assignment_override_created(override)
    post_event_stringified("assignment_override_created", get_assignment_override_data(override))
  end

  def self.assignment_override_updated(override)
    post_event_stringified("assignment_override_updated", get_assignment_override_data(override))
  end

  def self.get_submission_data(submission)
    event = {
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
      late: submission.late?,
      missing: submission.missing?,
      lti_assignment_id: submission.assignment.lti_context_id,
      group_id: submission.group_id,
      posted_at: submission.posted_at,
      workflow_state: submission.workflow_state,
    }
    actl = submission.assignment.assignment_configuration_tool_lookups.take
    if actl && (tool_proxy = Lti::ToolProxy.proxies_in_order_by_codes(
      context: submission.course,
      vendor_code: actl.tool_vendor_code,
      product_code: actl.tool_product_code,
      resource_type_code: actl.tool_resource_type_code
    ).first)
      event[:associated_integration_id] = tool_proxy.guid
    end
    event
  end

  def self.submission_event(event_type, submission)
    post_event_stringified(event_type, get_submission_data(submission), amended_context(submission.context))
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
    submission_event("submission_created", submission)
  end

  def self.submission_updated(submission)
    submission_event("submission_updated", submission)
  end

  def self.submission_comment_created(comment)
    payload = {
      submission_comment_id: comment.id,
      submission_id: comment.submission_id,
      user_id: comment.author_id,
      created_at: comment.created_at,
      attachment_ids: comment.attachment_ids.blank? ? [] : comment.attachment_ids.split(","),
      body: LiveEvents.truncate(comment.comment)
    }
    post_event_stringified("submission_comment_created", payload)
  end

  def self.plagiarism_resubmit(submission)
    submission_event("plagiarism_resubmit", submission)
  end

  def self.get_user_data(user)
    {
      user_id: user.global_id,
      uuid: user.uuid,
      name: user.name,
      short_name: user.short_name,
      workflow_state: user.workflow_state,
      created_at: user.created_at,
      updated_at: user.updated_at,
      user_login: user.primary_pseudonym&.unique_id,
      user_sis_id: user.primary_pseudonym&.sis_user_id
    }
  end

  def self.user_created(user)
    post_event_stringified("user_created", get_user_data(user))
  end

  def self.user_updated(user)
    post_event_stringified("user_updated", get_user_data(user))
  end

  def self.get_enrollment_data(enrollment)
    data = {
      enrollment_id: enrollment.global_id,
      course_id: enrollment.global_course_id,
      course_uuid: enrollment.course.uuid,
      user_id: enrollment.global_user_id,
      user_uuid: enrollment.user.uuid,
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
    post_event_stringified("enrollment_created", get_enrollment_data(enrollment))
  end

  def self.enrollment_updated(enrollment)
    post_event_stringified("enrollment_updated", get_enrollment_data(enrollment))
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
    post_event_stringified("enrollment_state_created", get_enrollment_state_data(enrollment_state))
  end

  def self.enrollment_state_updated(enrollment_state)
    post_event_stringified("enrollment_state_updated", get_enrollment_state_data(enrollment_state))
  end

  def self.user_account_association_created(assoc)
    post_event_stringified("user_account_association_created", {
                             user_id: assoc.global_user_id,
                             account_id: assoc.global_account_id,
                             account_uuid: assoc.account.uuid,
                             created_at: assoc.created_at,
                             updated_at: assoc.updated_at,
                             is_admin: !assoc.account.root_account.cached_all_account_users_for(assoc.user).empty?,
                           })
  end

  def self.logged_in(session, user, pseudonym)
    ctx = LiveEvents.get_context || {}
    ctx[:user_id] = user.global_id
    ctx[:user_login] = pseudonym.unique_id
    ctx[:user_account_id] = pseudonym.account.global_id
    ctx[:user_sis_id] = pseudonym.sis_user_id
    ctx[:session_id] = session[:session_id] if session[:session_id]
    post_event_stringified("logged_in",
                           {
                             redirect_url: session[:return_to]
                           },
                           ctx)
  end

  def self.logged_out
    post_event_stringified("logged_out", {})
  end

  def self.quiz_submitted(submission)
    # TODO: include score, for automatically graded portions?
    post_event_stringified("quiz_submitted", {
                             submission_id: submission.global_id,
                             quiz_id: submission.global_quiz_id
                           })
  end

  def self.wiki_page_created(page)
    post_event_stringified("wiki_page_created", {
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

    post_event_stringified("wiki_page_updated", payload)
  end

  def self.wiki_page_deleted(page)
    post_event_stringified("wiki_page_deleted", {
                             wiki_page_id: page.global_id,
                             title: LiveEvents.truncate(page.title)
                           })
  end

  def self.attachment_created(attachment)
    post_event_stringified("attachment_created", get_attachment_data(attachment))
  end

  def self.attachment_updated(attachment, old_display_name)
    payload = get_attachment_data(attachment)
    if old_display_name
      payload[:old_display_name] = LiveEvents.truncate(old_display_name)
    end

    post_event_stringified("attachment_updated", payload)
  end

  def self.attachment_deleted(attachment)
    post_event_stringified("attachment_deleted", get_attachment_data(attachment))
  end

  def self.grade_changed(submission, old_submission = nil, old_assignment = submission.assignment)
    grader_id = nil
    if submission.grader_id && !submission.autograded?
      grader_id = submission.global_grader_id
    end

    sis_pseudonym = GuardRail.activate(:secondary) do
      SisPseudonym.for(submission.user, submission.assignment.context, type: :trusted, require_sis: false)
    end

    post_event_stringified("grade_change",
                           {
                             submission_id: submission.global_id,
                             assignment_id: submission.global_assignment_id,
                             assignment_name: submission.assignment.name,
                             grade: submission.grade,
                             old_grade: old_submission.try(:grade),
                             score: submission.score,
                             old_score: old_submission.try(:score),
                             points_possible: submission.assignment.points_possible,
                             old_points_possible: old_assignment.points_possible,
                             grader_id:,
                             student_id: submission.global_user_id,
                             student_sis_id: sis_pseudonym&.sis_user_id,
                             user_id: submission.global_user_id,
                             grading_complete: submission.graded?,
                             muted: !submission.posted?
                           },
                           amended_context(submission.assignment.context))
  end

  def self.asset_access(asset, category, role, level, context: nil, context_membership: nil)
    asset_subtype = nil
    if asset.is_a?(Array)
      asset_subtype = asset[0]
      asset_obj = asset[1]
    else
      asset_obj = asset
    end

    enrollment_data = {}
    if context_membership.is_a?(Enrollment)
      enrollment_data = {
        enrollment_id: context_membership.id,
        section_id: context_membership.course_section_id
      }
    end

    post_event_stringified(
      "asset_accessed",
      {
        asset_name: asset_obj.try(:name) || asset_obj.try(:title),
        asset_type: asset_obj.class.reflection_type_name,
        asset_id: asset_obj.global_id,
        asset_subtype:,
        category:,
        role:,
        level:
      }.merge(LiveEvents::EventSerializerProvider.serialize(asset_obj)).merge(enrollment_data),
      amended_context(context)
    )
  end

  def self.quiz_export_complete(content_export)
    # when importing content export packages, migration_ids are obtained
    # from content_migrations, a content_migration and content_export can share
    # the same ID.
    # The "content-export-" prefix prevents from saving the same migration_id on
    # records that belong to different migrations
    post_event_stringified(
      "quiz_export_complete",
      quiz_export_complete_data(content_export),
      amended_context(content_export.context)
    )
  end

  def self.quiz_export_complete_data(content_export)
    (content_export.settings[:quizzes2] || {}
    ).merge({ content_export_id: "content-export-#{content_export.global_id}" })
  end

  def self.content_migration_completed(content_migration)
    post_event_stringified(
      "content_migration_completed",
      content_migration_data(content_migration),
      amended_context(content_migration.context)
    )
  end

  def self.content_migration_data(content_migration)
    context = content_migration.context
    import_quizzes_next =
      content_migration.migration_settings&.[](:import_quizzes_next) == true
    link_migration_during_import = import_quizzes_next && content_migration.asset_map_v2?
    need_resource_map = content_migration.source_course&.has_new_quizzes? || link_migration_during_import

    payload = {
      content_migration_id: content_migration.global_id,
      context_id: context.global_id,
      context_type: context.class.to_s,
      lti_context_id: context.lti_context_id,
      context_uuid: context.uuid,
      import_quizzes_next:,
      source_course_lti_id: content_migration.source_course&.lti_context_id,
      source_course_uuid: content_migration.source_course&.uuid,
      destination_course_lti_id: context.lti_context_id,
      migration_type: content_migration.migration_type,
      resource_map_url: content_migration.asset_map_url(generate_if_needed: need_resource_map)
    }

    if context.respond_to?(:root_account)
      payload[:domain] = context.root_account&.domain(ApplicationController.test_cluster_name)
    end

    payload
  end

  def self.course_section_created(section)
    post_event_stringified("course_section_created", get_course_section_data(section))
  end

  def self.course_section_updated(section)
    post_event_stringified("course_section_updated", get_course_section_data(section))
  end

  def self.quizzes_next_quiz_duplicated(payload)
    post_event_stringified("quizzes_next_quiz_duplicated", payload)
  end

  def self.quizzes_next_migration_urls_complete(payload)
    post_event_stringified("quizzes_next_migration_urls_complete", payload)
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
    post_event_stringified("module_created", get_context_module_data(context_module))
  end

  def self.module_updated(context_module)
    post_event_stringified("module_updated", get_context_module_data(context_module))
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
    post_event_stringified("module_item_created", get_context_module_item_data(context_module_item))
  end

  def self.module_item_updated(context_module_item)
    post_event_stringified("module_item_updated", get_context_module_item_data(context_module_item))
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

  def self.course_completed(context_module_progression)
    post_event_stringified("course_completed",
                           get_course_completed_data(
                             context_module_progression.context_module.course,
                             context_module_progression.user
                           ))
  end

  def self.course_progress(context_module_progression)
    post_event_stringified("course_progress", get_course_completed_data(context_module_progression.context_module.course, context_module_progression.user))
  end

  def self.get_course_completed_data(course, user)
    {
      progress: CourseProgress.new(course, user, read_only: true).to_json,
      user: user.slice(%i[id name email]),
      course: course.slice(%i[id name account_id sis_source_id])
    }
  end

  def self.get_learning_outcome_context_uuid(outcome_id)
    out = LearningOutcome.find_by(id: outcome_id)
    out&.context&.uuid
  end

  def self.rubric_assessment_learning_outcome_result_associated_asset(result)
    # By default associated_asset is nil for RubricAssessment LOR.  For what I can tell, there is no reason for this being
    # nil and should be updated to reflect the RubricAssociation association object. This work is accounted for in OUT-6303.
    # setting associated_asset to the Canvas assignment for Rubric Assessments
    if result.associated_asset.nil? && result.artifact_type == "RubricAssessment" && result.association_type == "RubricAssociation"
      rubric_association = RubricAssociation.find(result.association_id)
      result.associated_asset_id = rubric_association.association_id
      result.associated_asset_type = rubric_association.association_type
    end
  end

  def self.get_learning_outcome_result_data(result)
    {
      learning_outcome_id: result.learning_outcome_id,
      learning_outcome_context_uuid: get_learning_outcome_context_uuid(result.learning_outcome_id),
      mastery: result.mastery,
      score: result.score,
      created_at: result.created_at,
      attempt: result.attempt,
      possible: result.possible,
      original_score: result.original_score,
      original_possible: result.original_possible,
      original_mastery: result.original_mastery,
      assessed_at: result.assessed_at,
      percent: result.percent,
      workflow_state: result.workflow_state,
      user_uuid: result.user_uuid,
      artifact_id: result.artifact_id,
      artifact_type: result.artifact_type,
      associated_asset_id: result.associated_asset_id,
      associated_asset_type: result.associated_asset_type
    }
  end

  def self.learning_outcome_result_updated(result)
    # If the LOR's workflow_state is 'deleted' this mean the association object is deleted as well.
    # this can happen in multiple ways, the most likely case is that the rubric was updated which causes
    # the rubric association to be created.  After saving the new rubric association, it will call assert_uniqueness
    # which results in permanently removing the previous association leaving only the new RubricAssociation.
    # Given this, if the learning outcome results workflow state is deleted, do not worry about updating
    # the associated asset information as the rubric association no longer exists.
    rubric_assessment_learning_outcome_result_associated_asset(result) unless result.workflow_state == "deleted"
    post_event_stringified("learning_outcome_result_updated", get_learning_outcome_result_data(result).merge(updated_at: result.updated_at))
  end

  def self.learning_outcome_result_created(result)
    # If the LOR's workflow_state is 'deleted' this mean the association object is deleted as well.
    # this can happen in multiple ways, the most likely case is that the rubric was updated which causes
    # the rubric association to be created.  After saving the new rubric association, it will call assert_uniqueness
    # which results in permanently removing the previous association leaving only the new RubricAssociation.
    # Given this, if the learning outcome results workflow state is deleted, do not worry about updating
    # the associated asset information as the rubric association no longer exists.
    rubric_assessment_learning_outcome_result_associated_asset(result) unless result.workflow_state == "deleted"
    post_event_stringified("learning_outcome_result_created", get_learning_outcome_result_data(result))
  end

  # Since outcome service canvas learning_outcome global id record won't match outcomes service shard
  # we are also sending the root_account_uuid for the original outcome, however we only send the uuid
  # if the record is from another shard otherwise we send nil to indicate the id is for the current shard
  def self.get_root_account_uuid(copied_from_outcome_id)
    _, shard = Shard.local_id_for(copied_from_outcome_id)
    return if shard.nil?

    original_outcome = LearningOutcome.find(copied_from_outcome_id)

    original_outcome&.context&.root_account&.uuid
  end

  def self.get_learning_outcome_data(outcome)
    {
      learning_outcome_id: outcome.id,
      context_type: outcome.context_type,
      context_id: outcome.context_id,
      context_uuid: outcome.context&.uuid,
      display_name: outcome.display_name,
      short_description: outcome.short_description,
      description: outcome.description,
      vendor_guid: outcome.vendor_guid,
      calculation_method: outcome.calculation_method,
      calculation_int: outcome.calculation_int,
      rubric_criterion: outcome.rubric_criterion,
      title: outcome.title,
      workflow_state: outcome.workflow_state,
      copied_from_outcome_id: Shard.local_id_for(outcome.copied_from_outcome_id)&.first,
      original_outcome_root_account_uuid: get_root_account_uuid(outcome.copied_from_outcome_id)
    }
  end

  def self.learning_outcome_updated(outcome)
    post_event_stringified("learning_outcome_updated", get_learning_outcome_data(outcome).merge(updated_at: outcome.updated_at))
  end

  def self.learning_outcome_created(outcome)
    post_event_stringified("learning_outcome_created", get_learning_outcome_data(outcome))
  end

  def self.get_learning_outcome_group_context_uuid(group_id)
    group = LearningOutcomeGroup.find_by(id: group_id)
    group&.context&.uuid
  end

  def self.get_learning_outcome_group_data(group)
    {
      learning_outcome_group_id: group.id,
      context_id: group.context_id,
      context_uuid: group.context&.uuid,
      context_type: group.context_type,
      title: group.title,
      description: group.description,
      vendor_guid: group.vendor_guid,
      parent_outcome_group_id: group.learning_outcome_group_id,
      parent_outcome_group_context_uuid: get_learning_outcome_group_context_uuid(group.learning_outcome_group_id),
      workflow_state: group.workflow_state
    }
  end

  def self.learning_outcome_group_updated(group)
    post_event_stringified("learning_outcome_group_updated", get_learning_outcome_group_data(group).merge(updated_at: group.updated_at))
  end

  def self.learning_outcome_group_created(group)
    post_event_stringified("learning_outcome_group_created", get_learning_outcome_group_data(group))
  end

  def self.get_learning_outcome_link_data(link)
    {
      learning_outcome_link_id: link.id,
      learning_outcome_id: link.content_id,
      learning_outcome_context_uuid: get_learning_outcome_context_uuid(link.content_id),
      learning_outcome_group_id: link.associated_asset_id,
      learning_outcome_group_context_uuid: get_learning_outcome_group_context_uuid(link.associated_asset_id),
      context_id: link.context_id,
      context_type: link.context_type,
      workflow_state: link.workflow_state
    }
  end

  def self.learning_outcome_link_created(link)
    post_event_stringified("learning_outcome_link_created", get_learning_outcome_link_data(link))
  end

  def self.learning_outcome_link_updated(link)
    post_event_stringified("learning_outcome_link_updated", get_learning_outcome_link_data(link).merge(updated_at: link.updated_at))
  end

  def self.rubric_assessment_submitted_at(rubric_assessment)
    submitted_at = nil
    if rubric_assessment.artifact.is_a?(Submission)
      submitted_at = rubric_assessment.artifact.submitted_at
    end
    submitted_at.nil? ? rubric_assessment.updated_at : submitted_at
  end

  def self.rubric_assessment_attempt(rubric_assessment)
    attempt = nil
    if rubric_assessment.artifact.is_a?(Submission)
      attempt = rubric_assessment.artifact.attempt
    end
    attempt
  end

  def self.rubric_assessed(rubric_assessment)
    # context uuid may have the potential to be nil. Instead of throwing an error if
    # context uuid is nil, it will be up to the consumer of the live event to
    # handle as they deem fit.  This way the consumer can raise an error if
    # the data is expected and required by their service.
    uuid = rubric_assessment.rubric_association&.association_object&.context&.uuid

    data = {
      id: rubric_assessment.id,
      aligned_to_outcomes: rubric_assessment.aligned_outcome_ids.count.positive?,
      artifact_id: rubric_assessment.artifact_id,
      artifact_type: rubric_assessment.artifact_type,
      assessment_type: rubric_assessment.assessment_type,
      context_uuid: uuid,
      submitted_at: rubric_assessment_submitted_at(rubric_assessment),
      created_at: rubric_assessment.created_at,
      updated_at: rubric_assessment.updated_at,
      attempt: rubric_assessment_attempt(rubric_assessment)
    }

    post_event_stringified("rubric_assessed", data)
  end

  def self.grade_override(score, old_score, enrollment, course)
    return unless score.course_score && score.override_score != old_score

    data = {
      score_id: score.id,
      enrollment_id: score.enrollment_id,
      user_id: enrollment.user_id,
      course_id: enrollment.course_id,
      grading_period_id: score.grading_period_id,
      override_score: score.override_score,
      old_override_score: old_score,
      updated_at: score.updated_at,
    }
    post_event_stringified("grade_override", data, amended_context(course))
  end

  def self.course_grade_change(score, old_score_values, enrollment)
    data = {
      user_id: enrollment.user_id,
      course_id: enrollment.course_id,
      workflow_state: score.workflow_state,
      created_at: score.created_at,
      updated_at: score.updated_at,
      current_score: score.current_score,
      old_current_score: old_score_values[:current_score],
      final_score: score.final_score,
      old_final_score: old_score_values[:final_score],
      unposted_current_score: score.unposted_current_score,
      old_unposted_current_score: old_score_values[:unposted_current_score],
      unposted_final_score: score.unposted_final_score,
      old_unposted_final_score: old_score_values[:unposted_final_score]
    }
    post_event_stringified("course_grade_change", data, amended_context(score.course))
  end

  def self.sis_batch_payload(batch)
    {
      sis_batch_id: batch.id,
      account_id: batch.account_id,
      workflow_state: batch.workflow_state
    }
  end

  def self.sis_batch_created(batch)
    post_event_stringified("sis_batch_created", sis_batch_payload(batch))
  end

  def self.sis_batch_updated(batch)
    post_event_stringified("sis_batch_updated", sis_batch_payload(batch))
  end

  def self.outcome_proficiency_created(proficiency)
    post_event_stringified("outcome_proficiency_created", get_outcome_proficiency_data(proficiency))
  end

  def self.outcome_proficiency_updated(proficiency)
    post_event_stringified("outcome_proficiency_updated", get_outcome_proficiency_data(proficiency).merge(updated_at: proficiency.updated_at))
  end

  def self.get_outcome_proficiency_data(proficiency)
    ratings = proficiency.outcome_proficiency_ratings.map do |rating|
      get_outcome_proficiency_rating_data(rating)
    end
    {
      outcome_proficiency_id: proficiency.id,
      context_type: proficiency.context_type,
      context_id: proficiency.context_id,
      workflow_state: proficiency.workflow_state,
      outcome_proficiency_ratings: ratings
    }
  end

  def self.get_outcome_proficiency_rating_data(rating)
    {
      outcome_proficiency_rating_id: rating.id,
      description: rating.description,
      points: rating.points,
      mastery: rating.mastery,
      color: rating.color,
      workflow_state: rating.workflow_state
    }
  end

  def self.outcome_calculation_method_created(method)
    post_event_stringified("outcome_calculation_method_created", get_outcome_calculation_method_data(method))
  end

  def self.outcome_calculation_method_updated(method)
    post_event_stringified("outcome_calculation_method_updated", get_outcome_calculation_method_data(method).merge(updated_at: method.updated_at))
  end

  def self.get_outcome_calculation_method_data(method)
    {
      outcome_calculation_method_id: method.id,
      context_type: method.context_type,
      context_id: method.context_id,
      workflow_state: method.workflow_state,
      calculation_method: method.calculation_method,
      calculation_int: method.calculation_int
    }
  end

  def self.outcome_friendly_description_created(description)
    post_event_stringified("outcome_friendly_description_created", get_outcome_friendly_description_data(description))
  end

  def self.outcome_friendly_description_updated(description)
    post_event_stringified("outcome_friendly_description_updated", get_outcome_friendly_description_data(description).merge(updated_at: description.updated_at))
  end

  def self.get_outcome_friendly_description_data(description)
    {
      outcome_friendly_description_id: description.id,
      context_type: description.context_type,
      context_id: description.context_id,
      description: description.description,
      workflow_state: description.workflow_state,
      learning_outcome_id: description.learning_outcome_id,
      learning_outcome_context_uuid: get_learning_outcome_context_uuid(description.learning_outcome_id),
      root_account_id: description.root_account_id
    }
  end

  def self.master_template_created(master_template)
    post_event_stringified("master_template_created", get_master_template_created_data(master_template))
  end

  def self.get_master_template_created_data(master_template)
    {
      master_template_id: master_template.id,
      account_id: master_template.course.account.global_id,
      account_uuid: master_template.course.account.uuid,
      blueprint_course_id: master_template.course.global_id,
      blueprint_course_uuid: master_template.course.uuid,
      blueprint_course_title: master_template.course.name,
      blueprint_course_workflow_state: master_template.course.workflow_state
    }
  end

  def self.master_migration_completed(master_migration)
    post_event_stringified("master_migration_completed", master_migration_completed_data(master_migration))
  end

  def self.master_migration_completed_data(master_migration)
    {
      master_migration_id: master_migration.id,
      master_template_id: master_migration.master_template.id,
      account_id: master_migration.master_template.course.account.global_id,
      account_uuid: master_migration.master_template.course.account.uuid,
      blueprint_course_uuid: master_migration.master_template.course.uuid,
      blueprint_course_id: master_migration.master_template.course.global_id
    }
  end

  def self.blueprint_subscription_created(blueprint_subscription)
    post_event_stringified("blueprint_subscription_created", blueprint_subscription_data(blueprint_subscription))
  end

  def self.blueprint_subscription_deleted(blueprint_subscription)
    post_event_stringified("blueprint_subscription_deleted", blueprint_subscription_data(blueprint_subscription))
  end

  def self.blueprint_subscription_data(blueprint_subscription)
    {
      master_template_account_uuid: blueprint_subscription.master_template.course.account.uuid,
      master_template_id: blueprint_subscription.master_template_id,
      master_course_uuid: blueprint_subscription.master_template.course.uuid,
      child_subscription_id: blueprint_subscription.id,
      child_course_uuid: blueprint_subscription.child_course.uuid,
      child_course_account_uuid: blueprint_subscription.child_course.account.uuid
    }
  end

  def self.default_blueprint_restrictions_updated(master_template)
    post_event_stringified("default_blueprint_restrictions_updated", default_blueprint_restrictions_updated_data(master_template))
  end

  def self.default_blueprint_restrictions_updated_data(master_template)
    {
      canvas_course_id: master_template.course.id,
      canvas_course_uuid: master_template.course.uuid,
      restrictions: master_template.use_default_restrictions_by_type ? master_template.default_restrictions_by_type : master_template.default_restrictions
    }
  end

  def self.blueprint_restrictions_updated(master_content_tag)
    post_event_stringified("blueprint_restrictions_updated", blueprint_restrictions_updated_data(master_content_tag))
  end

  def self.blueprint_restrictions_updated_data(master_content_tag)
    lti_resource_link_id =
      (master_content_tag.content_type == "Assignment") ? master_content_tag.content.lti_resource_link_id : nil

    {
      canvas_assignment_id: master_content_tag.content_id,
      canvas_course_id: master_content_tag.master_template.course_id,
      canvas_course_uuid: master_content_tag.master_template.course.uuid,
      lti_resource_link_id:,
      restrictions: master_content_tag.restrictions,
      use_default_restrictions: master_content_tag.use_default_restrictions
    }
  end

  def self.heartbeat
    environment = if ApplicationController.test_cluster?
                    ApplicationController.test_cluster_name
                  else
                    Canvas.environment
                  end

    data = {
      environment:,
      region_code: Canvas.region_code || "not_configured",
      region: Canvas.region || "not_configured"
    }
    post_event_stringified("heartbeat", data)
  end

  def self.content_export_created(content_export)
    post_event_stringified(
      "content_export_created",
      content_export_data(content_export)
    )
  end

  def self.content_export_data(content_export)
    {
      content_export_id: content_export.global_id,
      export_type: content_export.export_type,
      created_at: content_export.created_at,
      context_id: content_export.context_id,
      context_uuid: content_export.context.uuid,
      context_type: content_export.context_type,
      settings: content_export.settings
    }
  end
end
