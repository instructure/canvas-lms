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

module Types
  class RatingInputType < Types::BaseEnum
    graphql_name "RatingInputType"
    value "not_liked", value: 0
    value "liked", value: 1
  end

  class ReportType < Types::BaseEnum
    graphql_name "ReportType"
    value "inappropriate", value: "inappropriate"
    value "offensive", value: "offensive"
    value "other", value: "other"
  end
end

class Mutations::UpdateDiscussionEntryParticipant < Mutations::BaseMutation
  graphql_name "UpdateDiscussionEntryParticipant"

  argument :discussion_entry_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("DiscussionEntry")
  argument :read, Boolean, required: false
  argument :rating, Types::RatingInputType, required: false
  argument :forced_read_state, Boolean, required: false
  argument :report_type, Types::ReportType, required: false

  field :discussion_entry, Types::DiscussionEntryType, null: false
  def resolve(input:)
    discussion_entry = DiscussionEntry.find(input[:discussion_entry_id])
    raise GraphQL::ExecutionError, "not found" unless discussion_entry.grants_right?(current_user, session, :read)

    unless input[:read].nil?
      opt = input[:forced_read_state].nil? ? {} : { forced: input[:forced_read_state] }
      discussion_entry.change_read_state(input[:read] ? "read" : "unread", current_user, opt)
    end

    unless input[:rating].nil?
      raise GraphQL::ExecutionError, "insufficient permissions" unless discussion_entry.grants_right?(current_user, session, :rate)

      discussion_entry.change_rating(input[:rating], current_user)
    end

    unless input[:report_type].nil?
      InstStatsd::Statsd.increment("discussion_entry_participant.report.created")
      discussion_entry.change_report_type(input[:report_type], current_user)
    end

    # TODO: VICE-1321
    # need to reload entry record as we currently return stale data
    {
      discussion_entry: discussion_entry.reload
    }
  rescue ActiveRecord::RecordNotFound
    raise GraphQL::ExecutionError, "not found"
  end
end
