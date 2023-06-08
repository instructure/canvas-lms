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

class Mutations::UpdateDiscussionThreadReadState < Mutations::BaseMutation
  graphql_name "UpdateDiscussionThreadReadState"

  argument :discussion_entry_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("DiscussionEntry")
  argument :read, Boolean, required: true

  field :discussion_entry, Types::DiscussionEntryType, null: false
  def resolve(input:)
    root_entry = DiscussionEntry.find(input[:discussion_entry_id])
    raise GraphQL::ExecutionError, "not found" unless root_entry.grants_right?(current_user, session, :read)

    read_state = input[:read] ? "read" : "unread"

    DiscussionEntryParticipant.upsert_for_root_entry_and_descendants(root_entry,
                                                                     current_user,
                                                                     new_state: read_state,
                                                                     forced: true)

    topic = root_entry.discussion_topic
    total_read_count = topic.discussion_entry_participants.read.where(
      discussion_entry_participants: { user_id: current_user.id }
    ).count
    topic.update_or_create_participant(current_user:, new_count: topic.default_unread_count - total_read_count)

    {
      discussion_entry: root_entry
    }
  rescue ActiveRecord::RecordNotFound
    raise GraphQL::ExecutionError, "not found"
  end
end
