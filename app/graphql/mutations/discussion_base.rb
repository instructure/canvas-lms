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

class Types::DiscussionCheckpointDateType < Types::BaseEnum
  graphql_name "DiscussionCheckpointDateType"
  description "Types of dates that can be set for discussion checkpoints"
  value "everyone"
  value "override"
end

class Types::DiscussionCheckpointDateSetType < Types::BaseEnum
  graphql_name "DiscussionCheckpointDateSetType"
  description "Types of date set that can be set for discussion checkpoints"
  value "CourseSection"
  value "Group"
  value "ADHOC"
end

class Mutations::DiscussionCheckpointDate < GraphQL::Schema::InputObject
  argument :id, Integer, required: false
  argument :type, Types::DiscussionCheckpointDateType, required: true
  argument :due_at, Types::DateTimeType, required: false
  argument :lock_at, Types::DateTimeType, required: false
  argument :unlock_at, Types::DateTimeType, required: false
  argument :student_ids, [Integer], required: false
  argument :set_type, Types::DiscussionCheckpointDateSetType, required: false
  argument :set_id, Integer, required: false

  def to_object
    {
      id: self[:id],
      type: self[:type],
      due_at: self[:due_at],
      lock_at: self[:lock_at],
      unlock_at: self[:unlock_at],
      student_ids: self[:student_ids],
      set_type: self[:set_type],
      set_id: self[:set_id]
    }
  end
end

class Mutations::DiscussionCheckpoints < GraphQL::Schema::InputObject
  argument :checkpoint_label, String, required: true
  argument :dates, [Mutations::DiscussionCheckpointDate], required: true
  argument :points_possible, Integer, required: true
  argument :replies_required, Integer, required: false
end

class Mutations::DiscussionBase < Mutations::BaseMutation
  argument :allow_rating, Boolean, required: false
  argument :delayed_post_at, Types::DateTimeType, required: false
  argument :group_category_id, ID, required: false
  argument :lock_at, Types::DateTimeType, required: false
  argument :locked, Boolean, required: false
  argument :message, String, required: false
  argument :only_graders_can_rate, Boolean, required: false
  argument :published, Boolean, required: false
  argument :require_initial_post, Boolean, required: false
  argument :title, String, required: false
  argument :todo_date, Types::DateTimeType, required: false
  argument :podcast_enabled, Boolean, required: false
  argument :podcast_has_student_posts, Boolean, required: false
  argument :specific_sections, String, required: false
  argument :file_id, ID, required: false, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Attachment")
  argument :checkpoints, [Mutations::DiscussionCheckpoints], required: false

  field :discussion_topic, Types::DiscussionType, null:

  # These are inputs that are allowed to be directly assigned from graphql to the model without additional processing or logic involved
  ALLOWED_INPUTS = %i[title message require_initial_post allow_rating only_graders_can_rate podcast_enabled podcast_has_student_posts].freeze

  def process_common_inputs(input, is_announcement, discussion_topic)
    model_attrs = input.to_h.slice(*ALLOWED_INPUTS)
    discussion_topic.assign_attributes(model_attrs)

    discussion_topic.workflow_state = "active" if input.key?(:published) && (input[:published] || is_announcement)

    unless is_announcement
      discussion_topic.todo_date = input[:todo_date] if input.key?(:todo_date)
      discussion_topic.group_category_id = input[:group_category_id] if input.key?(:group_category_id)
    end

    if input.key?(:file_id)
      attachment = Attachment.find(input[:file_id])
      raise ActiveRecord::RecordNotFound unless attachment.user == current_user

      unless discussion_topic.grants_right?(current_user, session, :attach)
        return validation_error(I18n.t("Insufficient attach permissions"))
      end

      discussion_topic.attachment = attachment
    end
  end

  def process_future_date_inputs(delayed_post_at, lock_at, discussion_topic)
    discussion_topic.delayed_post_at = delayed_post_at if delayed_post_at
    discussion_topic.lock_at = lock_at if lock_at

    if discussion_topic.delayed_post_at_changed? || discussion_topic.lock_at_changed?
      # only apply post_delayed if the topic is set to published
      discussion_topic.workflow_state = (discussion_topic.should_not_post_yet && discussion_topic.workflow_state == "active") ? "post_delayed" : discussion_topic.workflow_state
      if discussion_topic.should_lock_yet
        discussion_topic.lock(without_save: true)
      else
        discussion_topic.unlock(without_save: true)
      end
    end
  end

  def process_locked_parameter(locked, discussion_topic)
    return unless locked != discussion_topic.locked? && !discussion_topic.lock_at_changed?

    # TODO: Remove this comment when reused for Create/Update...
    # This makes no sense now but will help in the future when we
    # want to update the locked state of a discussion topic
    if locked
      discussion_topic.lock(without_save: true)
    else
      discussion_topic.lock_at = nil
      discussion_topic.unlock(without_save: true)
    end
  end

  def set_sections(specific_sections, discussion_topic)
    if specific_sections && specific_sections != "all"
      discussion_topic.is_section_specific = true
      section_ids = specific_sections
      section_ids = section_ids.split(",") if section_ids.is_a?(String)
      new_section_ids = section_ids.map { |id| Shard.relative_id_for(id, Shard.current, Shard.current) }.sort
      if discussion_topic.course_sections.pluck(:id).sort != new_section_ids
        discussion_topic.course_sections = CourseSection.find(new_section_ids)
        discussion_topic.sections_changed = true
      end
    else
      discussion_topic.is_section_specific = false
    end
  end

  def verify_specific_section_visibilities(discussion_topic)
    return unless discussion_topic.is_section_specific && discussion_topic.context.is_a?(Course)

    visibilities = discussion_topic.context.course_section_visibility(current_user)
    case visibilities
    when :all
      []
    when :none
      discussion_topic.course_sections.map(&:id)
    else
      discussion_topic.course_sections.map(&:id) - visibilities
    end
  end
end
