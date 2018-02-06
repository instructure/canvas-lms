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
  GroupType = GraphQL::ObjectType.define do
    name "Group"

    interfaces [Interfaces::TimestampInterface]

    field :_id, !types.ID, "legacy canvas id", property: :id
    field :name, types.String

    connection :membersConnection, GroupMembershipType.connection_type, resolve: ->(group, _, ctx) {
      if group.grants_right? ctx[:current_user], :read_roster
        group.group_memberships.where(
          workflow_state: GroupMembershipsController::ALLOWED_MEMBERSHIP_FILTER
        )
      else
        nil
      end
    }
  end
end
