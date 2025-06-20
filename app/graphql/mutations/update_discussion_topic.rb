# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

class Mutations::UpdateDiscussionTopic < Mutations::DiscussionBase
  include Api
  include Api::V1::AssignmentOverride
  include DiscussionTopicsHelper

  graphql_name "UpdateDiscussionTopic"

  # rubocop:disable GraphQL/ExtractInputType
  argument :anonymous_state, Types::DiscussionTopicAnonymousStateType, required: false
  argument :assignment, Mutations::AssignmentBase::AssignmentUpdate, required: false
  argument :discussion_topic_id, GraphQL::Schema::Object::ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("DiscussionTopic")
  argument :discussion_type, Types::DiscussionTopicDiscussionType, required: false
  argument :remove_attachment, Boolean, required: false
  # sets in-memory (not persisiting) flag to decide when to notify users about announcement changes
  argument :notify_users, Boolean, required: false
  argument :set_checkpoints, Boolean, required: false
  argument :ungraded_discussion_overrides, [Mutations::AssignmentBase::AssignmentOverrideCreateOrUpdate], required: false
  # rubocop:enable GraphQL/ExtractInputType

  field :discussion_topic, Types::DiscussionType
  def resolve(input:)
    @current_user = current_user

    discussion_topic = DiscussionTopic.find(input[:discussion_topic_id])
    raise GraphQL::ExecutionError, "insufficient permission" unless discussion_topic.grants_right?(current_user, :update)

    if input[:message] != discussion_topic.message && discussion_topic.editing_restricted?(:content)
      # editing is impossible frontwise, so we're just gonna ignore auto formatting
      input[:message] = discussion_topic.message
    elsif !input[:message].nil?
      input[:message] = Api::Html::Content.process_incoming(input[:message], host: context[:request].host, port: context[:request].port)
    end

    if input[:anonymous_state].present? && discussion_topic.discussion_subentry_count > 0
      return validation_error(I18n.t("Anonymity settings are locked due to a posted reply"))
    end

    if !discussion_topic.checkpoints? && input.dig(:assignment, :for_checkpoints) && (discussion_topic.discussion_entries&.active&.any? || discussion_topic.assignment&.has_student_submissions?)
      return validation_error(I18n.t("If there are replies, checkpoints cannot be enabled."))
    end

    unless input[:anonymous_state].nil?
      unless input[:anonymous_state] == "off"
        locked = input[:group_category_id].present?
        locked ||= input[:assignment].present? && input[:assignment][:set_assignment]
        return validation_error(I18n.t("Anonymity settings are locked for group and/or graded discussions")) if locked
      end

      discussion_topic.anonymous_state = (input[:anonymous_state] == "off") ? nil : input[:anonymous_state]
    end

    if discussion_topic.is_announcement
      # TODO: deprecate discussion_topic_section_visibilities for assignment_overrides LX-1498
      set_sections(input[:specific_sections], discussion_topic)
      invalid_sections = verify_specific_section_visibilities(discussion_topic) || []

      unless invalid_sections.empty?
        return validation_error(I18n.t("You do not have permissions to modify discussion for section(s) %{section_ids}", section_ids: invalid_sections.join(", ")))
      end
    end

    unless input[:published].nil?
      was_published = discussion_topic.published?
      if input[:published] && !was_published
        discussion_topic.publish!
      elsif input[:published] && was_published
        discussion_topic.edit!
      else
        discussion_topic.unpublish!
      end
    end

    if !input[:remove_attachment].nil? && input[:remove_attachment]
      discussion_topic.attachment_id = nil
    end

    # if the discussion has threaded messages, can't disable threaded messages
    if input[:discussion_type] == DiscussionTopic::DiscussionTypes::NOT_THREADED && discussion_topic.discussion_entries.where.not(parent_id: nil).where.not(workflow_state: "deleted").exists?
      return validation_error(I18n.t("Cannot disable threaded replies when there are threaded messages under this discussion"))
    end

    unless input[:discussion_type].nil?
      discussion_topic.discussion_type = input[:discussion_type]
    end

    # Validating default expand input data
    if input.key?(:expanded) && input.key?(:expanded_locked) && !input[:expanded] && input[:expanded_locked]
      return validation_error(I18n.t("Cannot set default thread state locked, when threads are collapsed"))
    end

    #  we need this to be set before the process commands since those will add group_category_id from the input
    is_already_a_group_discussion = discussion_topic.group_category_id.present?

    process_common_inputs(input, discussion_topic.is_announcement, discussion_topic)
    process_future_date_inputs(input.slice(:delayed_post_at, :lock_at), discussion_topic)
    process_locked_parameter(input[:locked], discussion_topic) unless input[:locked].nil?

    if input[:checkpoints].present?
      # If discussion topic has checkpoints, the sum of possible points cannot exceed the max for the assignment
      err_message = validate_possible_points_with_checkpoints(input)
      return validation_error(err_message) unless err_message.nil?

      if input[:checkpoints].present?
        # If discussion topic has checkpoints, the sum of possible points cannot exceed the max for the assignment
        err_message = validate_possible_points_with_checkpoints(input)
        return validation_error(err_message) unless err_message.nil?

        if is_already_a_group_discussion
          # Already a group discussion
          if !discussion_topic.checkpoints? && !discussion_topic.context.checkpoints_group_discussions_enabled?
            return validation_error(I18n.t("Group discussions cannot have checkpoints."))
          end
        elsif input[:group_category_id].present? && !discussion_topic.context.checkpoints_group_discussions_enabled?
          # Not already a group discussion, but trying to make it one
          return validation_error(I18n.t("Group discussions cannot have checkpoints."))
        end
      end
    end

    # Save the discussion topic before updating the assignment if the group category is being updated,
    # because creating group assignment overrides are dependent on the group category being set
    discussion_topic.save! if input.key?(:group_category_id)

    # Take care of Assignment update information
    if input[:assignment]
      assignment_id = discussion_topic&.assignment&.id || discussion_topic.old_assignment_id

      if assignment_id
        # If a current or old assignment exists already, then update it
        unless discussion_topic.root_topic_id?
          # The UpdateAssignment mutation requires an id, so we need to add it to the input
          updated_assignment_args = input[:assignment].to_h.merge(
            id: assignment_id.to_s
          )

          set_discussion_assignment_association(updated_assignment_args, discussion_topic)

          # Instantiate and execute UpdateAssignment mutation
          assignment_mutation = Mutations::UpdateAssignment.new(object: nil, context:, field: nil)
          assignment_result = assignment_mutation.resolve(input: updated_assignment_args)
          discussion_topic.assignment = assignment_result[:assignment] if input[:assignment][:set_assignment] != false
          discussion_topic.lock_at = input[:assignment][:lock_at] if input[:assignment][:set_assignment] != false
          discussion_topic.unlock_at = input[:assignment][:unlock_at] if input[:assignment][:set_assignment] != false

          if assignment_result[:errors]
            return { errors: assignment_result[:errors] }
          end
        end
      elsif input[:assignment][:set_assignment].nil? || input[:assignment][:set_assignment]
        # Create a new Assignment if set_assignment doesn't exist or is true.

        course_id = discussion_topic.course.id
        assignment_name = discussion_topic.title

        # Update the input hash with course_id and name. They are required for the CreateAssignment mutation
        assignment_input = input[:assignment].to_h.merge({
                                                           course_id: course_id.to_s,
                                                           name: assignment_name
                                                         })

        # Instantiate and execute CreateAssignment mutation
        assignment_create_mutation = Mutations::CreateAssignment.new(object:, context:, field: nil)
        assignment_create_result = assignment_create_mutation.resolve(input: assignment_input, submittable: discussion_topic)

        if assignment_create_result[:errors]
          return { errors: assignment_create_result[:errors] }
        end

        discussion_topic.assignment = assignment_create_result[:assignment]
        discussion_topic.lock_at = input[:assignment][:lock_at]
        discussion_topic.unlock_at = input[:assignment][:unlock_at]
      end

      # Assignment must be present to set checkpoints
      if discussion_topic.assignment && input[:checkpoints]&.count == DiscussionTopic::REQUIRED_CHECKPOINT_COUNT
        return validation_error(I18n.t("If checkpoints are defined, forCheckpoints: true must be provided to the discussion topic assignment.")) unless input.dig(:assignment, :for_checkpoints)

        # on the case of changing an ungraded discussion to a graded, checkpointed discussion, at this stage
        # has_sub_assignments? returns true, but sub_assignments is empty. We will want the creator service when this happens
        checkpoint_service = if discussion_topic.assignment.has_sub_assignments? && discussion_topic.assignment.sub_assignments.any?
                               Checkpoints::DiscussionCheckpointUpdaterService
                             else
                               Checkpoints::DiscussionCheckpointCreatorService
                             end

        input[:checkpoints].each do |checkpoint|
          dates = checkpoint[:dates]
          checkpoint_service.call(
            discussion_topic:,
            checkpoint_label: checkpoint[:checkpoint_label],
            points_possible: checkpoint[:points_possible],
            dates:,
            replies_required: checkpoint[:replies_required]
          )
        end
      end
    end

    if input[:notify_users]
      discussion_topic.notify_users = true
    end

    # Determine if the checkpoints are being deleted
    is_deleting_checkpoints = input.key?(:set_checkpoints) && !input[:set_checkpoints]

    if is_deleting_checkpoints
      Checkpoints::DiscussionCheckpointDeleterService.call(
        discussion_topic:
      )
    end

    discussion_topic.editor = current_user
    return errors_for(discussion_topic) unless discussion_topic.save!

    if input.key?(:ungraded_discussion_overrides)
      overrides = input[:ungraded_discussion_overrides] || []
      update_ungraded_discussion(discussion_topic, overrides)
    end

    discussion_topic.assignment = assignment_result[:assignment] if assignment_result && assignment_result[:assignment]

    {
      discussion_topic:
    }
  rescue ActiveRecord::RecordNotFound
    raise GraphQL::ExecutionError, "not found"
  rescue ArgumentError
    raise GraphQL::ExecutionError, "Assignment group category id and discussion topic group category id do not match"
  end
end

def set_discussion_assignment_association(assignment_params, discussion_topic)
  # Determine if the assignment is being deleted
  is_deleting_assignment = assignment_params.key?(:set_assignment) && !assignment_params[:set_assignment]

  if is_deleting_assignment && !discussion_topic&.assignment.nil?
    assignment = discussion_topic.assignment

    if assignment.has_sub_assignments
      Checkpoints::DiscussionCheckpointDeleterService.call(
        discussion_topic:
      )
    end

    discussion_topic.assignment = nil
    assignment.discussion_topic = nil
    assignment.destroy
  elsif (assignment = discussion_topic.assignment || discussion_topic.old_assignment)
    # Update assignment_params
    assignment_params[:state] = discussion_topic.published? ? "published" : "unpublished"
    assignment_params[:name] = discussion_topic.title

    validate_and_remove_group_category_id(assignment_params, discussion_topic) if assignment_params.key?(:group_category_id)

    # If a topic doesn't have a group_category_id or has submissions, then the assignment group_category_id should be nil
    unless discussion_topic.try(:group_category_id) || assignment.has_submitted_submissions?
      assignment_params[:group_category_id] = nil
    end

    # Finalize assignment restoration
    discussion_topic.assignment = assignment
    discussion_topic.sync_assignment
    # This save is required to prevent an extra discussion_topic from being created in the updateAssignment
    assignment.save!
  end
end

def validate_and_remove_group_category_id(assignment_params, discussion_topic)
  if assignment_params[:group_category_id].present? && discussion_topic.group_category_id.present? && assignment_params[:group_category_id] != discussion_topic.group_category_id.to_s
    raise ArgumentError, "Group category IDs do not match"
  end

  if assignment_params[:group_category_id].present?
    assignment_params.delete(:group_category_id)
  end
end
