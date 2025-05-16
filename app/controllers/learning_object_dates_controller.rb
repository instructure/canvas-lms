# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

# @API Learning Object Dates
#
# API for accessing date-related attributes on assignments, quizzes, modules, discussions, pages, and files. Note that
# support for files is not yet available.
#
# @model LearningObjectDates
#     {
#       "id": "LearningObjectDates",
#       "description": "",
#       "properties": {
#         "id": {
#           "description": "the ID of the learning object (not present for checkpoints)",
#           "example": 4,
#           "type": "integer"
#         },
#         "due_at": {
#           "description": "the due date for the learning object. returns null if not present or applicable. never applicable for ungraded discussions, pages, and files",
#           "example": "2012-07-01T23:59:00-06:00",
#           "type": "datetime"
#         },
#         "lock_at": {
#           "description": "the lock date (learning object is locked after this date). returns null if not present",
#           "example": "2012-07-01T23:59:00-06:00",
#           "type": "datetime"
#         },
#         "reply_to_topic_due_at": {
#           "description": "the reply_to_topic sub_assignment due_date. returns null if not present",
#           "example": "2012-07-01T23:59:00-06:00",
#           "type": "datetime"
#         },
#         "required_replies_due_at": {
#           "description": "the reply_to_entry sub_assignment due_date. returns null if not present",
#           "example": "2012-07-01T23:59:00-06:00",
#           "type": "datetime"
#         },
#         "unlock_at": {
#           "description": "the unlock date (learning object is unlocked after this date). returns null if not present",
#           "example": "2012-07-01T23:59:00-06:00",
#           "type": "datetime"
#         },
#         "only_visible_to_overrides": {
#           "description": "whether the learning object is only visible to overrides",
#           "example": false,
#           "type": "boolean"
#         },
#         "graded": {
#           "description": "whether the learning object is graded (and thus has a due date)",
#           "example": true,
#           "type": "boolean"
#         },
#         "blueprint_date_locks": {
#           "description": "[exclusive to blueprint child content only] list of lock types",
#           "example": ["due_dates", "availability_dates"],
#           "type": "array",
#           "items": {"type": "string"}
#         },
#         "visible_to_everyone": {
#           "description": "whether the learning object is visible to everyone",
#           "example": true,
#           "type": "boolean"
#         },
#         "overrides": {
#           "description": "paginated list of AssignmentOverride objects",
#           "type": "array",
#           "items": { "$ref": "AssignmentOverride" }
#         },
#         "checkpoints": {
#           "description": "list of Checkpoint objects, only present if a learning object has subAssignments",
#           "type": "array",
#           "items": { "$ref": "LearningObjectDates" }
#         },
#         "tag": {
#           "description": "the tag identifying the type of checkpoint (only present for checkpoints)",
#           "example": "reply_to_topic",
#           "type": "string"
#         }
#       }
#     }
class LearningObjectDatesController < ApplicationController
  before_action :require_user
  before_action :require_context
  before_action :check_authorized_action

  include Api::V1::LearningObjectDates
  include Api::V1::Assignment
  include Api::V1::AssignmentOverride
  include SubmittableHelper
  include DifferentiationTag

  OBJECTS_WITH_ASSIGNMENTS = %w[DiscussionTopic WikiPage].freeze

  # @API Get a learning object's date information
  #
  # Get a learning object's date-related information, including due date, availability dates,
  # override status, and a paginated list of all assignment overrides for the item.
  #
  # @returns LearningObjectDates
  def show
    route = polymorphic_url([:api_v1, @context, asset, :date_details])
    overrides = Api.paginate(overridable.all_assignment_overrides.active, self, route)

    # this is a temporary check for any discussion_topic_section_visibilities until we eventually backfill that table
    visibilities_to_override = if overridable.is_a?(DiscussionTopic) && overridable.is_section_specific
                                 section_overrides = overridable.assignment_overrides.active.where(set_type: "CourseSection").select(:set_id)
                                 section_visibilities = overridable.discussion_topic_section_visibilities.active.where.not(course_section_id: section_overrides)
                                 Api.paginate(section_visibilities, self, route)
                               end
    # @context here is always a course, which was requested by the API client
    include_child_override_due_dates = @context.discussion_checkpoints_enabled?
    all_overrides = assignment_overrides_json(overrides, @current_user, include_names: true, include_child_override_due_dates:)
    all_overrides += section_visibility_to_override_json(section_visibilities, overridable) if visibilities_to_override

    render json: {
      **learning_object_dates_json(asset, overridable),
      **blueprint_date_locks_json(asset),
      overrides: all_overrides,
    }
  end

  # @API Update a learning object's date information
  #
  # Updates date-related information for learning objects, including due date, availability dates,
  # override status, and assignment overrides.
  #
  # Returns 204 No Content response code if successful.
  #
  # @argument due_at [DateTime]
  #   The learning object's due date. Not applicable for ungraded discussions, pages, and files.
  #
  # @argument unlock_at [DateTime]
  #   The learning object's unlock date. Must be before the due date if there is one.
  #
  # @argument lock_at [DateTime]
  #   The learning object's lock date. Must be after the due date if there is one.
  #
  # @argument only_visible_to_overrides [Boolean]
  #   Whether the learning object is only assigned to students who are targeted by an override.
  #
  # @argument assignment_overrides[] [Array]
  #   List of overrides to apply to the learning object. Overrides that already exist should include
  #   an ID and will be updated if needed. New overrides will be created for overrides in the list
  #   without an ID. Overrides not included in the list will be deleted. Providing an empty list
  #   will delete all of the object's overrides. Keys for each override object can include: 'id',
  #   'title', 'due_at', 'unlock_at', 'lock_at', 'student_ids', and 'course_section_id', 'course_id',
  #   'noop_id', and 'unassign_item'.
  #
  # @example_request
  #   curl https://<canvas>/api/v1/courses/:course_id/assignments/:assignment_id/date_details \
  #     -X PUT \
  #     -H 'Authorization: Bearer <token>' \
  #     -H 'Content-Type: application/json' \
  #     -d '{
  #           "due_at": "2012-07-01T23:59:00-06:00",
  #           "unlock_at": "2012-06-01T00:00:00-06:00",
  #           "lock_at": "2012-08-01T00:00:00-06:00",
  #           "only_visible_to_overrides": true,
  #           "assignment_overrides": [
  #             {
  #               "id": 212,
  #               "course_section_id": 3564
  #             },
  #             {
  #               "title": "an assignment override",
  #               "student_ids": [1, 2, 3]
  #             }
  #           ]
  #         }'
  def update
    case asset.class_name
    when "Assignment"
      update_assignment(asset, object_update_params)
    when "Quizzes::Quiz"
      update_quiz(asset, object_update_params.except(:reply_to_topic_due_at, :required_replies_due_at))
    when "DiscussionTopic"
      asset.overrides_changed = true
      if asset == overridable
        update_ungraded_object(asset, object_update_params)
      else
        if asset.checkpoints?
          update_checkpointed_assignment(asset, object_update_params)
        else
          update_assignment(overridable, object_update_params)
        end
        prefer_assignment_availability_dates(asset, overridable)
      end
    when "WikiPage"
      if Account.site_admin.feature_enabled?(:create_wiki_page_mastery_path_overrides) || (asset == overridable && !wiki_page_needs_assignment?)

        update_ungraded_object(asset, object_update_params)
      elsif wiki_page_needs_assignment?
        apply_assignment_parameters(object_update_params.merge(set_assignment: true), asset)
      else
        update_assignment(overridable, object_update_params)
      end
    when "Attachment"
      update_ungraded_object(asset, object_update_params)
    end
  end

  def convert_tag_overrides_to_adhoc_overrides
    # Graded discussions have an assignment for due dates so use that
    learning_object = if asset.is_a?(DiscussionTopic) && asset.assignment
                        asset.assignment
                      else
                        asset
                      end

    errors = OverrideConverterService.convert_tags_to_adhoc_overrides_for(
      learning_object:,
      course: @context
    )

    if errors
      return render json: { errors: }, status: :bad_request
    end

    head :no_content
  end

  private

  def check_authorized_action
    return render json: { error: "This API does not support files." }, status: :bad_request if asset.is_a?(Attachment) && !Account.site_admin.feature_enabled?(:differentiated_files)

    render_unauthorized_action unless asset.grants_right?(@current_user, :manage_assign_to)
  end

  def asset
    @asset ||= if params[:assignment_id]
                 @context.active_assignments.find(params[:assignment_id])
               elsif params[:quiz_id]
                 @context.active_quizzes.find(params[:quiz_id])
               elsif params[:context_module_id]
                 @context.context_modules.not_deleted.find(params[:context_module_id])
               elsif params[:discussion_topic_id]
                 @context.discussion_topics.find(params[:discussion_topic_id])
               elsif params[:url_or_id]
                 @context.wiki.find_page(params[:url_or_id]) || not_found
               elsif params[:attachment_id]
                 @context.attachments.not_deleted.find(params[:attachment_id])
               end
  end

  # this is the object that has the overrides and the base dates (usually the same as the asset, but not always)
  def overridable
    # graded discussions have an assignment and are differentiated solely via that assignment
    # ungraded topics do not have an assignment and have direct overrides and availability dates
    # pages might have an assignment if they're "allowed in mastery paths"
    @overridable ||= (OBJECTS_WITH_ASSIGNMENTS.include?(asset.class_name) && asset.assignment) ? asset.assignment : asset
  end

  def update_assignment(assignment, params)
    assignment.updating_user = @current_user
    result = update_api_assignment(assignment, params, @current_user)
    return head :no_content if [:created, :ok].include?(result)

    render json: assignment.errors, status: (result == :forbidden) ? :forbidden : :bad_request
  end

  def update_checkpointed_assignment(discussion, params)
    checkpoint_service = Checkpoints::DiscussionCheckpointUpdaterService
    checkpoint_dates = prepare_checkpoints_dates(params)
    checkpoint_service.call(
      discussion_topic: discussion,
      checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
      dates: checkpoint_dates[:reply_to_topic][:dates],
      saved_by: :transaction
    )

    checkpoint_service.call(
      discussion_topic: discussion,
      checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
      dates: checkpoint_dates[:reply_to_entry][:dates],
      replies_required: discussion.reply_to_entry_required_count
    )
  end

  def prepare_checkpoints_dates(params)
    reply_to_topic_dates = []
    reply_to_entry_dates = []

    params[:assignment_overrides]&.each do |override|
      base_override = { type: "override" }

      %i[unlock_at lock_at unassign_item].each do |override_field|
        base_override[override_field] = override[override_field] if override.key?(override_field)
      end

      # If student_ids, course_section_id, or group_id is provided, then we want to provide the correct set_type and set ids
      if override[:student_ids]
        base_override[:set_type] = "ADHOC"
        base_override[:student_ids] = override[:student_ids]
      elsif override[:course_section_id]
        base_override[:set_type] = "CourseSection"
        base_override[:set_id] = override[:course_section_id]
      elsif override[:group_id]
        base_override[:set_type] = "Group"
        base_override[:set_id] = override[:group_id]
      elsif override[:course_id]
        base_override[:set_type] = "Course"
      end

      # each checkpoint has the same base_override attributes
      reply_to_topic_date = base_override.dup
      reply_to_entry_date = base_override.dup
      reply_to_topic_date[:due_at] = override[:reply_to_topic_due_at] if override.key?(:reply_to_topic_due_at)
      reply_to_entry_date[:due_at] = override[:required_replies_due_at] if override.key?(:required_replies_due_at)

      # If the override is provided, we assume it is the parent override, and we need to find the correct child_override
      # That should get updated in the discussionCheckpointUpdaterService
      if override[:id]
        parent_override = AssignmentOverride.find(override[:id])
        reply_to_topic_override = parent_override.child_overrides.find { |o| o.assignment.sub_assignment_tag == CheckpointLabels::REPLY_TO_TOPIC }
        reply_to_entry_override = parent_override.child_overrides.find { |o| o.assignment.sub_assignment_tag == CheckpointLabels::REPLY_TO_ENTRY }

        reply_to_topic_date[:id] = reply_to_topic_override&.id
        reply_to_entry_date[:id] = reply_to_entry_override&.id
      end

      reply_to_topic_dates << reply_to_topic_date
      reply_to_entry_dates << reply_to_entry_date
    end

    # Add base dates for everyone only if not only_visible_to_overrides
    unless params[:only_visible_to_overrides]
      base_everyone_date = { type: "everyone" }

      [:unlock_at, :lock_at].each do |date_field|
        base_everyone_date[date_field] = params[date_field] if params.key?(date_field)
      end

      reply_to_topic_date = base_everyone_date.dup
      reply_to_topic_date[:due_at] = params[:reply_to_topic_due_at] if params.key?(:reply_to_topic_due_at)
      reply_to_topic_dates << reply_to_topic_date

      reply_to_entry_date = base_everyone_date.dup
      reply_to_entry_date[:due_at] = params[:required_replies_due_at] if params.key?(:required_replies_due_at)
      reply_to_entry_dates << reply_to_entry_date
    end

    {
      reply_to_topic: { dates: reply_to_topic_dates },
      reply_to_entry: { dates: reply_to_entry_dates }
    }
  end

  def remove_differentiation_tag_overrides(overrides_to_delete)
    tag_overrides = overrides_to_delete.select { |o| o.set_type == "Group" && o.set.non_collaborative? }
    tag_overrides.each(&:destroy!)
  end

  def update_quiz(quiz, params)
    return render json: quiz.errors, status: :forbidden unless grading_periods_allow_submittable_update?(quiz, params)

    overrides = params.delete :assignment_overrides
    if overrides
      batch = prepare_assignment_overrides_for_batch_update(quiz, overrides, @current_user)
      return render json: quiz.errors, status: :forbidden unless grading_periods_allow_assignment_overrides_batch_update?(quiz, batch)

      quiz.assignment&.validate_overrides_for_sis(overrides)
    end

    Assignment.suspend_due_date_caching do
      quiz.transaction do
        # remove differentiation tag overrides if they are being deleted
        # and account setting is disabled. The quiz will fail validation
        # if these overrides exist and the account setting is disabled
        if !@context.account.allow_assign_to_differentiation_tags? && batch.present?
          remove_differentiation_tag_overrides(batch[:overrides_to_delete])
        end

        quiz.update!(params)
        perform_batch_update_assignment_overrides(quiz, batch) if overrides
      end
    end

    if quiz.assignment
      quiz.assignment.clear_cache_key(:availability)
      SubmissionLifecycleManager.recompute(quiz.assignment, update_grades: true, executing_user: @current_user)
    end

    head :no_content
  end

  def update_ungraded_object(object, params)
    overrides = params.delete :assignment_overrides
    batch = prepare_assignment_overrides_for_batch_update(object, overrides, @current_user) if overrides
    object.transaction do
      object.update!(params)
      perform_batch_update_assignment_overrides(object, batch) if overrides
      # this is temporary until we are able to remove the dicussion_topic_section_visibilities table
      if object.is_a?(DiscussionTopic) && object.is_section_specific
        object.discussion_topic_section_visibilities.destroy_all
        object.update!(is_section_specific: false)
      end
    end
    object.clear_cache_key(:availability) if caches_availability?
    head :no_content
  end

  def prefer_assignment_availability_dates(object, assignment)
    return unless object.is_a?(DiscussionTopic) && assignment

    object.delayed_post_at = nil if assignment.unlock_at.present?
    object.unlock_at = nil if assignment.unlock_at.present?
    object.lock_at = nil if assignment.lock_at.present?
    object.save! if object.changed?
  end

  def allow_due_at?
    asset.is_a?(Assignment) || asset.is_a?(Quizzes::Quiz) || (asset.is_a?(DiscussionTopic) && asset.assignment)
  end

  def caches_availability?
    asset.is_a?(Assignment) || asset.is_a?(Quizzes::Quiz) || asset.is_a?(DiscussionTopic) || asset.is_a?(WikiPage)
  end

  def wiki_page_needs_assignment?
    asset.is_a?(WikiPage) &&
      asset.assignment.nil? &&
      @context.conditional_release? &&
      params[:assignment_overrides]&.any? { |override| override[:noop_id].present? }
  end

  def object_update_params
    allowed_params = [:unlock_at,
                      :lock_at,
                      :only_visible_to_overrides,
                      { assignment_overrides: strong_anything }]
    allowed_params.unshift(:due_at) if allow_due_at?
    allowed_params.unshift(:reply_to_topic_due_at) if allow_due_at?
    allowed_params.unshift(:required_replies_due_at) if allow_due_at?
    params.permit(*allowed_params)
  end
end
