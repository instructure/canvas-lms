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

module Types
  class GradingPeriodType < ApplicationObjectType
    graphql_name "GradingPeriod"

    implements GraphQL::Types::Relay::Node
    implements Interfaces::TimestampInterface
    implements Interfaces::LegacyIDInterface

    global_id_field :id

    field :title, String, null: true
    field :is_last, Boolean, null: false
    def is_last
      object.last?
    end

    field :start_date, DateTimeType, null: true
    field :end_date, DateTimeType, null: true
    field :close_date, DateTimeType, <<~MD, null: true
      assignments can only be graded before the grading period closes
    MD

    field :weight, Float, <<~MD, null: true
      used to calculate how much the assignments in this grading period
      contribute to the overall grade
    MD
    def weight
      object.grading_period_group.weighted ? object.weight.to_f : nil
    end

    field :display_totals, Boolean, null: false
    def display_totals
      object.grading_period_group.display_totals_for_all_grading_periods
    end
  end
end
