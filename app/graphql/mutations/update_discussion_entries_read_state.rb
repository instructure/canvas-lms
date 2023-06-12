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

class Mutations::UpdateDiscussionEntriesReadState < Mutations::BaseMutation
  graphql_name "UpdateDiscussionEntriesReadState"

  argument :discussion_entry_ids, [ID], required: true, prepare: GraphQLHelpers.relay_or_legacy_ids_prepare_func("DiscussionEntry")
  argument :read, Boolean, required: true

  field :discussion_entries, [Types::DiscussionEntryType], null: true
  def resolve(input:)
    return validation_error(I18n.t("Discussion entry ids must have at least one id")) if input[:discussion_entry_ids].blank?

    entries = DiscussionEntry.where(id: input[:discussion_entry_ids])
    raise GraphQL::ExecutionError, "not found" if entries.count != input[:discussion_entry_ids].count

    # return error if provided any ids the user doesn't have permission to read
    entries.each do |entry|
      raise GraphQL::ExecutionError, "not found" unless entry.grants_right?(current_user, session, :read)
    end

    entry = entries.first
    state = input[:read] ? :read : :unread
    ids = DiscussionEntryParticipant.upsert_for_entries(entry, current_user, batch: entries, new_state: state, forced: true)

    # only run this if upsert_for_entries really returned ids
    if ids
      offset = (state == :read) ? -ids.length : ids.length
      entry.discussion_topic.update_or_create_participant(current_user:, offset:)
    end

    {
      discussion_entries: entries
    }
  end
end
