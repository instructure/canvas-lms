# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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
  class GradingPeriodGroupType < ApplicationObjectType
    graphql_name "GradingPeriodGroup"

    implements GraphQL::Types::Relay::Node
    implements Interfaces::TimestampInterface
    implements Interfaces::LegacyIDInterface

    global_id_field :id

    field :title, String, null: true
    field :weighted, Boolean, null: false
    def weighted
      !!object.weighted
    end

    field :display_totals, Boolean, null: false
    def display_totals
      object.display_totals_for_all_grading_periods
    end

    field :grading_periods_connection, GradingPeriodType.connection_type, null: true
    def grading_periods_connection
      object.grading_periods.where(workflow_state: "active")
    end

    field :enrollment_term_ids, [String], null: false
    def enrollment_term_ids
      object.enrollment_term_ids.map(&:to_s)
    end
  end
end
