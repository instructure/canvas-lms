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
class RatingInputType < Types::BaseEnum
  graphql_name 'RatingInputType'
  value 'not_liked', value: 0
  value 'liked', value: 1
end

class Mutations::UpdateDiscussionEntryParticipant < Mutations::BaseMutation
  graphql_name 'UpdateDiscussionEntryParticipant'

  argument :discussion_entry_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func('DiscussionEntry')
  argument :read, Boolean, required: false
  argument :rating, RatingInputType, required: false

  field :discussion_entry, Types::DiscussionEntryType, null: false
  def resolve(input:)
    discussion_entry = DiscussionEntry.find(input[:discussion_entry_id])
    raise GraphQL::ExecutionError, "not found" unless discussion_entry.grants_right?(current_user, session, :read)

    unless input[:read].nil?
      input[:read] ? discussion_entry.change_read_state('read', current_user) : discussion_entry.change_read_state('unread', current_user)
    end

    unless input[:rating].nil?
      raise GraphQL::ExecutionError, "insufficient permissions" unless discussion_entry.grants_right?(current_user, session, :rate)

      discussion_entry.change_rating(input[:rating], current_user)
    end

    {
      discussion_entry: discussion_entry
    }
  rescue ActiveRecord::RecordNotFound
    raise GraphQL::ExecutionError, 'not found'
  end
end
