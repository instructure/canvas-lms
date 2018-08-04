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

module Types
  class AssignmentGroupType < ApplicationObjectType
    graphql_name "AssignmentGroup"

    implements GraphQL::Relay::Node.interface
    implements Interfaces::TimestampInterface

    AssignmentGroupState = GraphQL::EnumType.define do
      name "AssignmentGroupState"
      description "States that Assignment Group can be in"
      value "available"
      value "deleted"
    end

    field :_id, ID, "legacy canvas id", method: :id, null: false
    field :name, String, null: true
    field :rules, AssignmentGroupRulesType, method: :rules_hash, null: true
    field :group_weight, Float, null: true
    field :position, Int, null: true
    field :state, AssignmentGroupState, method: :workflow_state, null: false

    implements Interfaces::AssignmentsConnectionInterface
    def assignments_connection(filter: {})
      load_association(:context) { |course|
        super(course: course, filter: filter)
      }
    end

    def assignments_scope(*args)
      super(*args).where(assignment_group_id: object.id)
    end
    private :assignments_scope
  end
end
