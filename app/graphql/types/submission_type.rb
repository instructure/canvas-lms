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

module Types
  class SubmissionType < ApplicationObjectType
    graphql_name 'Submission'

    implements GraphQL::Types::Relay::Node
    implements Interfaces::TimestampInterface
    implements Interfaces::SubmissionInterface

    field :_id, ID, 'legacy canvas id', method: :id, null: false
    global_id_field :id

    # NOTE: In most cases you shouldn't add new fields here, instead they should
    #       be added to interfaces/submission_interface.rb so that they work for
    #       both submissions and submission histories

    field :submission_histories_connection, SubmissionHistoryType.connection_type, null: true do
      argument :include_current_submission, Boolean, <<~DESC, required: false, default_value: true
        If the most current submission should be included in the submission
        history results. Defaults to true.
      DESC
    end
    def submission_histories_connection(include_current_submission: true)
      Promise.all([
        load_association(:versions),
        load_association(:assignment)
      ]).then do
        histories = object.submission_history
        histories.pop unless include_current_submission
        histories
      end
    end
  end
end
