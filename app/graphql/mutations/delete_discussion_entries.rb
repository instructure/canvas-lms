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

class Mutations::DeleteDiscussionEntries < Mutations::BaseMutation
  graphql_name "DeleteDiscussionEntries"

  # input arguments
  argument :ids, [ID], required: true, prepare: GraphQLHelpers.relay_or_legacy_ids_prepare_func('DiscussionEntry')

  field :discussion_entry_ids, [ID], null: true

  def resolve(input:)
    errors = {}
    resolved_ids = []
    context[:deleted_models] = { discussion_entries: {}}
    entries = DiscussionEntry.where(id: input[:ids])

    missing_entry_ids = input[:ids].map(&:to_i) - entries.map(&:id)
    invalid_entries = entries.reject{|e| e.grants_right?(current_user, nil, :delete) }
    readable_invalid_entries = invalid_entries.select{|e| e.grants_right?(current_user, nil, :read) }
    bad_entry_ids = (missing_entry_ids + invalid_entries.map(&:id)).uniq

    bad_entry_ids.each{|id| errors[id] = "Unable to find Discussion Entry" }
    readable_invalid_entries.each{|e| errors[e.id] = "Insufficient permissions" }

    valid_entries = entries - invalid_entries
    
    resolved_ids = valid_entries.map do |discussion_entry|
      discussion_entry.destroy
      context[:deleted_models][:discussion_entries][discussion_entry.id] = discussion_entry
      discussion_entry.id
    end.compact

    response = {}
    response[:discussion_entry_ids] = resolved_ids if resolved_ids.any?
    response[:errors] = errors if errors.any?
    response
  rescue ActiveRecord::RecordInvalid => e
    errors_for(e.record)
  end

  def self.discussion_entry_ids_log_entry(entry, context)
    context[:deleted_models][:discussion_entries][entry]
  end
end
