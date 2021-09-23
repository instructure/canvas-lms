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
class Mutations::DeleteDiscussionTopic < Mutations::BaseMutation
  graphql_name "DeleteDiscussionTopic"
  # input arguments
  argument :id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func('DiscussionTopic')

  # the return data if the delete is successful
  field :discussion_topic_id, ID, null: false

  def resolve(input:)
    record = DiscussionTopic.active.find_by(id: input[:id])
    raise GraphQL::ExecutionError, "Unable to find Discussion Topic" if record.nil? || !record.grants_right?(current_user, nil, :read)

    unless record.grants_right?(current_user, nil, :delete)
      raise GraphQL::ExecutionError, "Insufficient permissions"
    end

    context[:deleted_models] = { discussion_topic: {}}
    context[:deleted_models][:discussion_topic] = record
    record.destroy
    {
      discussion_topic_id: record.id
    }
  end

  def self.discussion_topic_id_log_entry(_topic, context)
    context[:deleted_models][:discussion_topic]
  end
end
