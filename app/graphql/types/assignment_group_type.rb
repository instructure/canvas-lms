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
  AssignmentGroupType = GraphQL::ObjectType.define do
    name "AssignmentGroup"

    implements GraphQL::Relay::Node.interface
    interfaces [Interfaces::TimestampInterface]

    global_id_field :id
    field :_id, !types.ID, "legacy canvas id", property: :id
    field :name, types.String
    field :rules, AssignmentGroupRulesType, property: :rules_hash
    field :groupWeight, types.Float, property: :group_weight
    field :position, types.Int
    field :state, !AssignmentGroupState, property: :workflow_state
    connection :assignmentsConnection, AssignmentType.connection_type, property: :assignments
  end

  AssignmentGroupState = GraphQL::EnumType.define do
    name "AssignmentGroupState"
    description "States that Assignment Group can be in"
    value "available"
    value "deleted"
  end
end
