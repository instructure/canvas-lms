#
# Copyright (C) 2017 Instructure, Inc.
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
  GroupMembershipType = GraphQL::ObjectType.define do
    name "GroupMembership"

    interfaces [Interfaces::TimestampInterface]

    field :_id, !types.ID, "legacy canvas id", property: :id

    field :state, !GroupMembershipStateType, property: :workflow_state

    field :user, UserType, resolve: ->(gm, _, _) {
      Loaders::AssociationLoader.for(GroupMembership, :user).load(gm).then {
        gm.user
      }
    }
  end

  GroupMembershipStateType = GraphQL::EnumType.define do
    name "GroupMembershipState"
    value "accepted"
    value "invited"
    value "requested"
    value "rejected"
    value "deleted"
  end
end
