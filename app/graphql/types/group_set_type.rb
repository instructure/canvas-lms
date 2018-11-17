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
  class GroupSetType < ApplicationObjectType
    graphql_name "GroupSet"

    alias set object

    implements GraphQL::Types::Relay::Node

    global_id_field :id
    field :_id, ID, "legacy canvas id", method: :id, null: false

    field :name, String, null: true

    class SelfSignupPolicyType < BaseEnum
      graphql_name "SelfSignupPolicy"
      description <<~DESC
        Determines if/how a student may join a group. A student can belong to
        only one group per group set at a time.
      DESC

      value "enabled", "students may join any group", value: "enabled"
      value "restricted", "students may join a group in their section", value: "restricted"
      value "disabled", "self signup is not allowed"
    end

    field :member_limit, Integer, <<~DESC, method: :group_limit, null: true
      Sets a cap on the number of members in the group.  Only applies when
      self-signup is enabled.
    DESC

    field :self_signup, SelfSignupPolicyType, null: false
    def self_signup
      set.self_signup || "disabled"
    end

    class AutoLeaderPolicyType < BaseEnum
      graphql_name "AutoLeaderPolicy"
      description "Determines if/how a leader is chosen for each group"

      value "random", "a leader is chosen at random", value: "random"
      value "first", "the first student assigned to the group is the leader", value: "first"
    end

    field :auto_leader, AutoLeaderPolicyType, null: true

    field :groups_connection, GroupType.connection_type, null: true
    def groups_connection
      Loaders::AssociationLoader.for(GroupCategory, :context).load(set).then {
        # this permission matches the REST api, but is probably too strict.
        # students are able to see groups in the canvas ui, so probably should
        # be able to see them here too
        set.context.grants_right?(current_user, :manage_groups) ?
          set.groups.active.by_name :
          nil
      }
    end
  end
end
