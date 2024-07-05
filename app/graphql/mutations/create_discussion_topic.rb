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

class Types::DiscussionTopicContextType < Types::BaseEnum
  graphql_name "DiscussionTopicContextType"
  description "Context types that can be associated with discussionTopics"
  value "Course"
  value "Group"
end

class Mutations::CreateDiscussionTopic < Mutations::DiscussionBase
  include Api
  include Api::V1::AssignmentOverride

  graphql_name "CreateDiscussionTopic"

  argument :is_announcement, Boolean, required: false
  argument :is_anonymous_author, Boolean, required: false
  argument :anonymous_state, Types::DiscussionTopicAnonymousStateType, required: false
  argument :context_id, GraphQL::Schema::Object::ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Context")
  argument :context_type, Types::DiscussionTopicContextType, required: true
  argument :assignment, Mutations::AssignmentBase::AssignmentCreate, required: false
  argument :ungraded_discussion_overrides, [Mutations::AssignmentBase::AssignmentOverrideCreateOrUpdate], required: false

  # most arguments inherited from DiscussionBase

  def resolve(input:)
    @current_user = current_user

    discussion_topic_context = find_context(input)
    return validation_error(I18n.t("Invalid context")) unless discussion_topic_context

    anonymous_state = input[:anonymous_state]

    # if the passed value is neither "partial_anonymity" nor "full_anonymity", set it to nil
    if anonymous_state && anonymous_state != "partial_anonymity" && anonymous_state != "full_anonymity"
      anonymous_state = nil
    end

    if anonymous_state &&
       discussion_topic_context.is_a?(Course) &&
       !discussion_topic_context.settings[:allow_student_anonymous_discussion_topics] &&
       !discussion_topic_context.grants_right?(current_user, session, :manage)
      return validation_error(I18n.t("You are not able to create an anonymous discussion"))
    end

    if anonymous_state && discussion_topic_context.is_a?(Group)
      return validation_error(I18n.t("You are not able to create an anonymous discussion in a group"))
    end

    # TODO: return an error when user tries to create a graded anonymous discussion

    if input[:todo_date] && !discussion_topic_context.grants_any_right?(current_user, session, :manage_content, :manage_course_content_add)
      return validation_error(I18n.t("You do not have permission to add this topic to the student to-do list."))
    end

    # validate course id for discussion topic and assignment match
    if input.key?(:assignment) && input[:assignment].present?
      assignment_context_id = GraphQLHelpers.parse_relay_or_legacy_id(input[:assignment].to_h[:course_id], "Course")
      if assignment_context_id != discussion_topic_context.id.to_s
        return validation_error(I18n.t("Assignment context_id must match discussion topic context_id"))
      end
    end

    # TODO: return an error when user tries to add a todo_date to a graded discussion

    is_announcement = input[:is_announcement] || false

    # TODO: On update, we load here instead of creating a new one.
    discussion_topic = is_announcement ? Announcement.new : DiscussionTopic.new

    # These fields are needed when creating a new discussion topic or announcement
    discussion_topic.context_id = discussion_topic_context.id
    discussion_topic.context_type = input[:context_type]
    discussion_topic.user = current_user
    discussion_topic.workflow_state = (input[:published] || is_announcement) ? "active" : "unpublished"

    verify_authorized_action!(discussion_topic, :create)

    # This can only be done on creation, also not common.
    unless is_announcement
      discussion_topic.is_anonymous_author = input[:is_anonymous_author] || false
      discussion_topic.anonymous_state = anonymous_state
    end

    if (!input.key?(:ungraded_discussion_overrides) && !Account.site_admin.feature_enabled?(:selective_release_ui_api)) || is_announcement
      # TODO: deprecate discussion_topic_section_visibilities for assignment_overrides LX-1498
      set_sections(input[:specific_sections], discussion_topic)
      invalid_sections = verify_specific_section_visibilities(discussion_topic) || []

      unless invalid_sections.empty?
        return validation_error(I18n.t("You do not have permissions to modify discussion for section(s) %{section_ids}", section_ids: invalid_sections.join(", ")))
      end
    end

    process_common_inputs(input, is_announcement, discussion_topic)
    process_future_date_inputs(input.slice(:delayed_post_at, :lock_at), discussion_topic)
    process_locked_parameter(input[:locked], discussion_topic)

    if input.key?(:assignment) && input[:assignment].present?
      working_assignment = Mutations::CreateAssignment.new(object:, context:, field: nil)
                                                      &.resolve(input: input[:assignment], submittable: discussion_topic)

      if working_assignment[:errors].present?
        return validation_error(working_assignment[:errors])
      elsif working_assignment.present?
        discussion_topic.assignment = working_assignment&.[](:assignment)
      end

      # Assignment must be present to set checkpoints
      if input[:checkpoints]&.count == DiscussionTopic::REQUIRED_CHECKPOINT_COUNT
        return validation_error(I18n.t("If checkpoints are defined, forCheckpoints: true must be provided to the discussion topic assignment.")) unless input.dig(:assignment, :for_checkpoints)

        input[:checkpoints].each do |checkpoint|
          dates = checkpoint[:dates]

          Checkpoints::DiscussionCheckpointCreatorService.call(
            discussion_topic:,
            checkpoint_label: checkpoint[:checkpoint_label],
            points_possible: checkpoint[:points_possible],
            dates:,
            replies_required: checkpoint[:replies_required]
          )
        end
      end
    end

    discussion_topic.saved_by = :assignment if discussion_topic.assignment.present?
    return errors_for(discussion_topic) unless discussion_topic.save!

    if input.key?(:ungraded_discussion_overrides)
      overrides = input[:ungraded_discussion_overrides] || []
      update_ungraded_discussion(discussion_topic, overrides)
    end

    { discussion_topic: }
  rescue Checkpoints::DiscussionCheckpointError => e
    raise GraphQL::ExecutionError, e.message
  rescue ActiveRecord::RecordInvalid
    errors_for(discussion_topic)
  rescue ActiveRecord::RecordNotFound
    raise GraphQL::ExecutionError, "Not found"
  end

  def find_context(input)
    context_id = GraphQLHelpers.parse_relay_or_legacy_id(input[:context_id], "Context")

    if input[:context_type] == "Course"
      Course.find(context_id)
    elsif input[:context_type] == "Group"
      Group.find(context_id)
    else
      nil
    end
  end
end
