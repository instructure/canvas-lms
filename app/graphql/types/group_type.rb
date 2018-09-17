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
  class GroupType < ApplicationObjectType
    graphql_name "Group"

    alias :group :object

    implements GraphQL::Relay::Node.interface
    implements Interfaces::TimestampInterface

    field :_id, ID, "legacy canvas id", method: :id, null: false
    field :name, String, null: true

    field :members_connection, GroupMembershipType.connection_type, null: true
    def members_connection
      if group.grants_right?(current_user, :read_roster)
        group.group_memberships.where(
          workflow_state: GroupMembershipsController::ALLOWED_MEMBERSHIP_FILTER
        )
      else
        nil
      end
    end
  end
end
