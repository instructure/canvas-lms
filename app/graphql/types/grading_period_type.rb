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
  GradingPeriodType = GraphQL::ObjectType.define do
    name "GradingPeriod"

    implements GraphQL::Relay::Node.interface
    interfaces [Interfaces::TimestampInterface]

    global_id_field :id
    field :_id, !types.ID, "legacy canvas id", property: :id

    field :title, types.String

    field :startDate, DateTimeType, property: :start_date
    field :endDate, DateTimeType, property: :end_date
    field :closeDate, DateTimeType, <<-DOC, property: :close_date
    assignments can only be graded before the grading period closes
    DOC

    field :weight, types.Float, <<-DOC
    used to calculate how much the assignments in this grading period
    contribute to the overall grade
    DOC
  end
end
