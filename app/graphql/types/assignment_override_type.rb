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
  AssignmentOverrideSetUnion = GraphQL::UnionType.define do
    name "AssignmentOverrideSet"

    description "Objects that can be assigned overridden dates"

    possible_types [SectionType, GroupType, AdhocStudentsType]

    resolve_type ->(obj, _) {
      case obj
      when CourseSection then SectionType
      when Group then GroupType
      when AssignmentOverride then AdhocStudentsType
      end
    }
  end

  AdhocStudentsType = GraphQL::ObjectType.define do
    name "AdhocStudents"

    description "A list of students that an `AssignmentOverride` applies to"

    field :students, types[UserType], resolve: ->(override, _, _) {
      Loaders::AssociationLoader.for(AssignmentOverride,
                                     assignment_override_students: :user)
      .load(override)
      .then { override.assignment_override_students.map(&:user) }
    }

  end
  class AssignmentOverrideType < ApplicationObjectType
    graphql_name "AssignmentOverride"

    implements GraphQL::Relay::Node.interface
    implements Interfaces::TimestampInterface

    alias :override :object

    field :_id, ID, "legacy canvas id", method: :id, null: false

    field :assignment, AssignmentType, null: true
    def assignment
      load_association(:assignment)
    end

    field :title, String, null: true

    field :set, AssignmentOverrideSetUnion,
      "This object specifies what students this override applies to",
      null: true
    def set
      if override.set_type == "ADHOC"
        override
      else
        load_association(:set)
      end
    end

    field :due_at, DateTimeType, null: true
    field :lock_at, DateTimeType, null: true
    field :unlock_at, DateTimeType, null: true
    field :all_day, Boolean, null: true
  end
end
