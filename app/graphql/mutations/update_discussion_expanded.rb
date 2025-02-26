# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

# TODO: after VICE-5047 gets to production, we can remove this mutation
class Mutations::UpdateDiscussionExpanded < Mutations::BaseMutation
  graphql_name "UpdateDiscussionExpanded"

  argument :discussion_topic_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("DiscussionEntry")
  argument :expanded, Boolean, required: true
  field :discussion_topic, Types::DiscussionType, null: false

  def resolve(input:)
    discussion_topic = DiscussionTopic.find(input[:discussion_topic_id])
    raise GraphQL::ExecutionError, "insufficient permission" unless discussion_topic.grants_right?(current_user, session, :read)

    discussion_topic.update_or_create_participant(current_user:, expanded: input[:expanded]) unless Account.site_admin.feature_enabled?(:discussion_default_expand) && discussion_topic.expanded_locked?
    { discussion_topic: }
  rescue ActiveRecord::RecordNotFound
    raise GraphQL::ExecutionError, "not found"
  end
end
