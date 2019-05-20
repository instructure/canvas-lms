#
# Copyright (C) 2018 - present Instructure, Inc.
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

class SubmissionHistoryEdgeType < GraphQL::Types::Relay::BaseEdge
  node_type(Types::SubmissionHistoryType)

  def node
    # Submission models or version ids for submission models can be handled here.
    if object.node.is_a? Integer
      Loaders::IDLoader.for(Version).load(object.node).then(&:model)
    else
      object.node
    end
  end
end

class SubmissionHistoryConnection < GraphQL::Types::Relay::BaseConnection
  edge_type(SubmissionHistoryEdgeType)

  def nodes
    # Submission models or version ids for submission models can be handled here.
    node_values = super
    version_ids, submissions = node_values.partition { |n| n.is_a? Integer }
    Loaders::IDLoader.for(Version).load_many(version_ids).then do |versions|
      versions.map(&:model) + submissions
    end
  end
end


module Types
  class SubmissionType < ApplicationObjectType
    graphql_name 'Submission'

    implements GraphQL::Types::Relay::Node
    implements Interfaces::TimestampInterface
    implements Interfaces::SubmissionInterface

    field :_id, ID, 'legacy canvas id', method: :id, null: false
    global_id_field :id

    field :submission_histories_connection, SubmissionHistoryConnection, null: true, connection: true
    def submission_histories_connection
      # There is not a version saved for submission attempt zero, so we fake it
      # here. If there are no versions, we are still on attempt zero and can use
      # the current submission, otherwise we fudge it with a model that is not
      # actually persisted to the database.
      submission_zero = if object.version_ids.empty?
        object
      else
        Submission.new(
          id: object.id,
          assignment_id: object.assignment_id,
          user_id: object.user_id,
          submission_type: object.submission_type,
          workflow_state: 'unsubmitted',
          created_at: object.created_at,
          updated_at: object.created_at, # Don't use the current updated_at time
          group_id: object.group_id,
          attempt: 0,
          context_code: object.context_code
        )
      end

      object.version_ids + [submission_zero]
    end
  end
end
