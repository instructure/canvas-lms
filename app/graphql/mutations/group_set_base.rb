# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

module Mutations
  class Types::AutoLeaderType < Types::BaseEnum
    graphql_name "AutoLeaderType"
    description "Method of selecting an automatic leader for groups"
    value "first"
    value "random"
  end

  class Types::GroupSetContextType < Types::BaseEnum
    graphql_name "GroupSetContextType"
    description "Type of context for group set"
    value "account", value: "Account"
    value "course", value: "Course"
  end

  class GroupSetBase < BaseMutation
    # group set
    argument :context_id, ID, required: true
    argument :context_type, Types::GroupSetContextType, required: true
    argument :name, String, required: true

    # various options for creating group set
    argument :assign_async, Boolean, required: false
    argument :assign_unassigned_members, Boolean, required: false
    argument :auto_leader_type, Types::AutoLeaderType, required: false
    argument :create_group_count, Int, required: false
    argument :create_group_member_count, Int, required: false
    argument :enable_auto_leader, Boolean, required: false
    argument :enable_self_signup, Boolean, required: false
    argument :group_by_section, Boolean, required: false
    argument :group_limit, Int, required: false
    argument :non_collaborative, Boolean, required: false
    argument :restrict_self_signup, Boolean, required: false
    argument :self_signup, Boolean, required: false

    field :group_set, Types::GroupSetType, null: true
  end
end
