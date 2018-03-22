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

CanvasSchema = GraphQL::Schema.define do
  query(Types::QueryType)
  mutation(Types::MutationType)

  use GraphQL::Batch

  id_from_object ->(obj, type_def, _) {
    GraphQL::Schema::UniqueWithinType.encode(type_def.name, obj.id)
  }

  object_from_id ->(relay_id, ctx) {
    type, id = GraphQL::Schema::UniqueWithinType.decode(relay_id)

    GraphQLNodeLoader.load(type, id, ctx)
  }

  resolve_type ->(_type, obj, ctx) {
    case obj
    when Course then Types::CourseType
    when Assignment then Types::AssignmentType
    when CourseSection then Types::SectionType
    when User then Types::UserType
    when Enrollment then Types::EnrollmentType
    when GradingPeriod then Types::GradingPeriodType
    end
  }

  instrument :field, AssignmentOverrideInstrumenter.new
end
