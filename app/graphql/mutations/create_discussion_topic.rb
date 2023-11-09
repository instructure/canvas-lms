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
class Mutations::CreateDiscussionTopic < Mutations::DiscussionBase
  graphql_name "CreateDiscussionTopic"

  argument :is_announcement, Boolean, required: false
  argument :is_anonymous_author, Boolean, required: false
  argument :anonymous_state, String, required: false
  argument :context_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Context")
  argument :context_type, String, required: true
  # most arguments inherited from DiscussionBase

  def resolve(input:)
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

    # TODO: return an error when user tries to add a todo_date to a graded discussion

    is_announcement = input[:is_announcement] || false

    # TODO: On update, we load here instead of creating a new one.
    discussion_topic = is_announcement ? Announcement.new : DiscussionTopic.new

    # This fields aren't common because they are just needed when it is a new discussion topic or announcement
    discussion_topic.context_id = discussion_topic_context.id
    discussion_topic.context_type = input[:context_type]

    verify_authorized_action!(discussion_topic, :create)

    # This can only be done on creation, also not common.
    unless is_announcement
      discussion_topic.is_anonymous_author = input[:is_anonymous_author] || false
      discussion_topic.anonymous_state = anonymous_state
    end

    set_sections(input[:specific_sections], discussion_topic)
    invalid_sections = verify_specific_section_visibilities(discussion_topic) || []

    unless invalid_sections.empty?
      return validation_error(I18n.t("You do not have permissions to modify discussion for section(s) %{section_ids}", section_ids: invalid_sections.join(", ")))
    end

    process_common_inputs(input, is_announcement, discussion_topic, true)
    process_future_date_inputs(input[:delayed_post_at], input[:lock_at], discussion_topic)
    process_locked_parameter(input[:locked], discussion_topic)

    topic_assignment = discussion_topic.build_assignment(input[:assignment].to_h) if input[:assignment]

    return validation_error(I18n.t("You do not have permissions to create assignments in the provided course")) unless topic_assignment.nil? || topic_assignment&.grants_right?(current_user, :create)

    discussion_topic.assignment = topic_assignment if topic_assignment&.grants_right?(current_user, :create)
    return errors_for(discussion_topic) unless discussion_topic.save

    if topic_assignment
      return errors_for(topic_assignment) unless topic_assignment.save
    end

    { discussion_topic: }
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
