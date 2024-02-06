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
  graphql_name "UpdateDiscussionTopic"

  argument :discussion_topic_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("DiscussionTopic")
  argument :remove_attachment, Boolean, required: false
  argument :assignment, Mutations::AssignmentUpdate, required: false
  argument :set_checkpoints, Boolean, required: false

  field :discussion_topic, Types::DiscussionType, null: false
  def resolve(input:)
    @current_user = current_user

    discussion_topic = DiscussionTopic.find(input[:discussion_topic_id])
    raise GraphQL::ExecutionError, "insufficient permission" unless discussion_topic.grants_right?(current_user, :update)

    unless input[:published].nil?
      input[:published] ? discussion_topic.publish! : discussion_topic.unpublish!
    end

    unless input[:locked].nil?
      input[:locked] ? discussion_topic.lock! : discussion_topic.unlock!
    end

    set_sections(input[:specific_sections], discussion_topic)
    invalid_sections = verify_specific_section_visibilities(discussion_topic) || []

    unless invalid_sections.empty?
      return validation_error(I18n.t("You do not have permissions to modify discussion for section(s) %{section_ids}", section_ids: invalid_sections.join(", ")))
    end

    if !input[:remove_attachment].nil? && input[:remove_attachment]
      discussion_topic.attachment_id = nil
    end

    process_common_inputs(input, discussion_topic.is_announcement, discussion_topic)
    process_future_date_inputs(input[:delayed_post_at], input[:lock_at], discussion_topic)

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
        assignment_create_result = assignment_create_mutation.resolve(input: assignment_input)

        if assignment_create_result[:errors]
          return { errors: assignment_create_result[:errors] }
        end

        discussion_topic.assignment = assignment_create_result[:assignment]
      end

      # Assignment must be present to set checkpoints
      if discussion_topic.assignment && input[:checkpoints]&.count == DiscussionTopic::REQUIRED_CHECKPOINT_COUNT
        return validation_error(I18n.t("If checkpoints are defined, forCheckpoints: true must be provided to the discussion topic assignment.")) unless input.dig(:assignment, :for_checkpoints)

        input[:checkpoints].each do |checkpoint|
          dates = checkpoint[:dates]&.map(&:to_object)

          Checkpoints::DiscussionCheckpointUpdaterService.call(
            discussion_topic:,
            checkpoint_label: checkpoint[:checkpoint_label],
            points_possible: checkpoint[:points_possible],
            dates:,
            replies_required: checkpoint[:replies_required]
          )
        end
      end
    end

    # Determine if the checkpoints are being deleted
    is_deleting_checkpoints = input.key?(:set_checkpoints) && !input[:set_checkpoints]

    if is_deleting_checkpoints
      Checkpoints::DiscussionCheckpointDeleterService.call(
        discussion_topic:
      )
    end

    return errors_for(discussion_topic) unless discussion_topic.save!

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
