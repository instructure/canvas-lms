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

  argument :context_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Context")
  argument :context_type, String, required: true
  # most arguments inherited from DiscussionBase

  field :discussion_topic, Types::DiscussionType, null: true
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

    # TODO: these were taken from the front-end, they still need to be implemented here
    # isAnnouncement: false,
    # discussionType: 'side_comment',
    # delayedPostAt: availableFrom,
    # lockAt: availableUntil,
    # podcastEnabled: enablePodcastFeed,
    # podcastHasStudentPosts: includeRepliesInFeed,
    # requireInitialPost: respondBeforeReply,
    # pinned: false,
    # todoDate,
    # groupCategoryId: null,
    # allowRating: allowLiking,
    # onlyGradersCanRate: onlyGradersCanLike,
    # anonymousState: discussionAnonymousState === 'off' ? null : discussionAnonymousState,
    # isAnonymousAuthor: anonymousAuthorState,
    # specificSections: sectionIdsToPostTo,
    # locked: false,

    discussion_topic = DiscussionTopic.new(
      {
        context_id: discussion_topic_context.id,
        context_type: input[:context_type],
        title: input[:title],
        message: input[:message],
        workflow_state: input[:published] ? "active" : "unpublished"
      }
    )

    return validation_error(I18n.t("Insufficient Permissions")) unless discussion_topic&.grants_right? current_user, :create

    response = {}
    if discussion_topic.save
      response[:discussion_topic] = discussion_topic
    else
      errors = errors_for(discussion_topic)
      response[:errors] = errors if errors.any?
    end

    response
  rescue ActiveRecord::RecordNotFound
    raise GraphQL::ExecutionError, "Not found"
  end
end
