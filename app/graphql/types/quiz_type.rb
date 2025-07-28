# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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
  # TODO: inherit from app-specific object
  class QuizType < ApplicationObjectType
    graphql_name "Quiz"

    implements GraphQL::Types::Relay::Node
    implements Interfaces::TimestampInterface
    implements Interfaces::ModuleItemInterface
    implements Interfaces::LegacyIDInterface

    global_id_field :id

    field :anonymous_submissions, Boolean, null: false

    field :submissions_connection, Types::SubmissionType.connection_type, null: true do
      description "submissions for this quiz's assignment"
      argument :filter, Types::SubmissionSearchFilterInputType, required: false
      argument :order_by, [Types::SubmissionSearchOrderInputType], required: false
    end
    def submissions_connection(filter: nil, order_by: nil)
      return nil if current_user.nil? || object.assignment.nil?

      filter = filter.to_h
      order_by ||= []
      filter[:states] ||= Types::DEFAULT_SUBMISSION_STATES
      filter[:states] = filter[:states] + ["unsubmitted"].freeze if filter[:include_unsubmitted]
      filter[:order_by] = order_by.map(&:to_h)
      SubmissionSearch.new(object.assignment, current_user, session, filter).search
    end
  end
end
