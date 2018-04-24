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
  AssignmentOverrideType = GraphQL::ObjectType.define do
    name "AssignmentOverride"

    interfaces [Interfaces::TimestampInterface]

    field :_id, !types.ID, "legacy canvas id", property: :id

    field :assignment, AssignmentType, resolve: ->(override, _, _) {
      Loaders::AssociationLoader.for(AssignmentOverride, :assignment)
        .load(override)
        .then { override.assignment }
    }

    field :title, types.String

    field :set, AssignmentOverrideSetUnion do
      description "This object specifies what students this override applies to"

      resolve ->(override, _, _) {
        if override.set_type == "ADHOC"
          # AdhocStudentsType will load the actual students
          override
        else
          Loaders::AssociationLoader.for(AssignmentOverride, :set)
            .load(override)
            .then { override.set }
        end
      }
    end

    field :dueAt, DateTimeType, property: :due_at
    field :lockAt, DateTimeType, property: :lock_at
    field :unlockAt, DateTimeType, property: :unlock_at
    field :allDay, types.Boolean, property: :all_day
  end

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
end
