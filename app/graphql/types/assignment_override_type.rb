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
  class AdhocStudentsType < ApplicationObjectType
    graphql_name "AdhocStudents"

    description "A list of students that an `AssignmentOverride` applies to"

    alias_method :override, :object

    field :students, [UserType], null: true

    def students
      load_association(:assignment_override_students).then do |override_students|
        Loaders::AssociationLoader.for(AssignmentOverrideStudent, :user).load_many(override_students)
      end
    end
  end

  Noop = Struct.new(:id)

  class NoopType < ApplicationObjectType
    graphql_name "Noop"

    description "A descriptive tag that doesn't link the assignment to a set"

    field :_id, ID, method: :id, null: false
  end

  class AssignmentOverrideSetUnion < BaseUnion
    graphql_name "AssignmentOverrideSet"

    description "Objects that can be assigned overridden dates"

    possible_types SectionType, GroupType, AdhocStudentsType, NoopType, CourseType

    def self.resolve_type(obj, _)
      case obj
      when CourseSection then SectionType
      when Group then GroupType
      when Course then CourseType
      when Noop then NoopType
      when AssignmentOverride then AdhocStudentsType
      end
    end
  end

  class AssignmentOverrideType < ApplicationObjectType
    graphql_name "AssignmentOverride"

    implements GraphQL::Types::Relay::Node
    implements Interfaces::TimestampInterface
    implements Interfaces::LegacyIDInterface

    alias_method :override, :object

    field :assignment, AssignmentType, null: true
    def assignment
      load_association(:assignment)
    end

    field :title, String, null: true

    field :set,
          AssignmentOverrideSetUnion,
          "This object specifies what students this override applies to",
          null: true
    def set
      case override.set_type
      when "ADHOC"
        override
      when "Noop"
        Noop.new(override.set_id)
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
