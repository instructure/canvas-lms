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

  argument :is_anonymous_author, Boolean, required: false
  argument :anonymous_state, String, required: false
  argument :context_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Context")
  argument :context_type, String, required: true
  # most arguments inherited from DiscussionBase

  def resolve(input:)
    # "context" is already a variable (the context of the mutation)
    # which is why this is "discussion_topic_context(_id)"
    discussion_topic_context_id = GraphQLHelpers.parse_relay_or_legacy_id(input[:context_id], "Context")

    # TODO: potentially create ContextType GraphQL type
    if input[:context_type] == "Course"
      discussion_topic_context = Course.find(discussion_topic_context_id)
    elsif input[:context_type] == "Group"
      discussion_topic_context ||= Group.find(discussion_topic_context_id)
    else
      return validation_error(I18n.t("Invalid context type"))
    end

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

    discussion_topic = DiscussionTopic.new(
      {
        context_id: discussion_topic_context.id,
        context_type: input[:context_type],
        title: input[:title],
        message: input[:message],
        workflow_state: input[:published] ? "active" : "unpublished",
        require_initial_post: input[:require_initial_post],
        is_anonymous_author: input[:is_anonymous_author] || false,
        anonymous_state:,
        allow_rating: input[:allow_rating],
        only_graders_can_rate: input[:only_graders_can_rate],
        user: current_user,
        todo_date: input[:todo_date],
        podcast_enabled: input[:podcast_enabled] || false,
        podcast_has_student_posts: input[:podcast_has_student_posts] || false
      }
    )
    verify_authorized_action!(discussion_topic, :create)

    process_future_date_inputs(input[:delayed_post_at], input[:lock_at], discussion_topic)

    return errors_for(discussion_topic) unless discussion_topic.save

    { discussion_topic: }
  rescue ActiveRecord::RecordNotFound
    raise GraphQL::ExecutionError, "Not found"
  end

  def process_future_date_inputs(delayed_post_at, lock_at, discussion_topic)
    discussion_topic.delayed_post_at = delayed_post_at if delayed_post_at
    discussion_topic.lock_at = lock_at if lock_at

    if discussion_topic.delayed_post_at_changed? || discussion_topic.lock_at_changed?
      discussion_topic.workflow_state = discussion_topic.should_not_post_yet ? "post_delayed" : discussion_topic.workflow_state
      if discussion_topic.should_lock_yet
        discussion_topic.lock(without_save: true)
      else
        discussion_topic.unlock(without_save: true)
      end
    end
  end
end
