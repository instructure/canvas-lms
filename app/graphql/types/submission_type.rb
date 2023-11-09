# frozen_string_literal: true

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

#############################################################################
# NOTE: In most cases you shouldn't add new fields here, instead they should
#       be added to interfaces/submission_interface.rb so that they work for
#       both submissions and submission histories
#############################################################################

module Types
  class SubmissionHistoryFilterInputType < Types::BaseInputObject
    graphql_name "SubmissionHistoryFilterInput"

    argument :states,
             [SubmissionStateType],
             required: false,
             default_value: DEFAULT_SUBMISSION_HISTORY_STATES

    argument :include_current_submission, Boolean, <<~MD, required: false, default_value: true
      If the most current submission should be included in the submission
      history results. Defaults to true.
    MD
  end

  class SubmissionType < ApplicationObjectType
    graphql_name "Submission"

    implements GraphQL::Types::Relay::Node
    implements Interfaces::TimestampInterface
    implements Interfaces::SubmissionInterface
    implements Interfaces::LegacyIDInterface

    global_id_field :id

    field :cached_due_date, DateTimeType, null: true

    field :custom_grade_status, String, null: true
    def custom_grade_status
      CustomGradeStatus.find(object.custom_grade_status_id).name if object.custom_grade_status_id
    end

    field :read_state, String, null: true
    def read_state
      object.read_state(current_user)
    end

    field :grading_period_id, ID, null: true

    field :student_entered_score, Float, null: true

    field :redo_request, Boolean, null: true

    field :user_id, ID, null: false

    field :submission_histories_connection, SubmissionHistoryType.connection_type, null: true do
      argument :filter, SubmissionHistoryFilterInputType, required: false, default_value: {}
    end
    def submission_histories_connection(filter:)
      filter = filter.to_h
      states, include_current_submission = filter.values_at(:states, :include_current_submission)

      Promise.all([
                    load_association(:versions),
                    load_association(:assignment)
                  ]).then do
        histories = object.submission_history
        histories.pop unless include_current_submission
        histories.select { |h| states.include?(h.workflow_state) }
      end
    end
  end
end
