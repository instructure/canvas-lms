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

    implements Interfaces::TimestampInterface

    # IDs could be nil since DiscussionTopicSectionVisibilities are not persisted
    # So we use expect null IDs instead of implementing Interfaces::LegacyIDInterface
    # and GraphQL::Types::Relay::Node
    field :_id, ID, "legacy canvas id", method: :id, null: true
    field :id, ID, resolver_method: :default_global_id, null: true

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
    field :unassign_item, Boolean, null: true
    field :context_module, ModuleType, null: true
    def context_module
      load_association(:context_module)
    end

    # GraphQL::Types::Relay::Node uses Types::Relay::NodeBehaviors#default_global_id
    # to resolve the id field. For non-persisted overrides, the ones that we use
    # for representing DiscussionTopicSectionVisibility with dummy objects, we get
    # the same id for all, so we need to add this validation instead.
    def default_global_id
      if object.id.nil?
        nil
      else
        context.schema.id_from_object(object, self.class, context)
      end
    end
  end
end
