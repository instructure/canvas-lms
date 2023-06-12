# frozen_string_literal: true

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

    alias_method :group, :object

    implements GraphQL::Types::Relay::Node
    implements Interfaces::TimestampInterface
    implements Interfaces::LegacyIDInterface
    implements Interfaces::AssetStringInterface

    global_id_field :id

    field :name, String, null: true

    field :members_count, Integer, null: true

    field :can_message, Boolean, null: false
    def can_message
      group.grants_right?(current_user, :send_messages)
    end

    field :members_connection, GroupMembershipType.connection_type, null: true
    def members_connection
      if group.grants_right?(current_user, :read_roster)
        members_scope
      end
    end

    field :member, GroupMembershipType, null: true do
      argument :user_id,
               ID,
               prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("User"),
               required: true
    end
    def member(user_id:)
      if group.grants_right?(current_user, :read_roster)
        members_scope.then do |m|
          Loaders::ForeignKeyLoader.for(m, :user_id).load(user_id)
                                   .then { |memberships| memberships&.first }
        end
      end
    end

    field :sis_id, String, null: true
    def sis_id
      load_association(:root_account).then do |root_account|
        group.sis_source_id if root_account.grants_any_right?(current_user, :read_sis, :manage_sis)
      end
    end

    def members_scope
      load_association(:group_memberships).then do |group_memberships|
        group_memberships.where(workflow_state: GroupMembershipsController::ALLOWED_MEMBERSHIP_FILTER)
      end
    end
    private :members_scope
  end
end
