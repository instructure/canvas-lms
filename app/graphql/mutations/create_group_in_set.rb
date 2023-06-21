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

class Mutations::CreateGroupInSet < Mutations::BaseMutation
  graphql_name "CreateGroupInSet"

  argument :name, String, required: true
  argument :group_set_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("GroupSet")

  field :group, Types::GroupType, null: true

  def resolve(input:)
    category_id = GraphQLHelpers.parse_relay_or_legacy_id(input[:group_set_id], "GroupSet")
    set = GroupCategory.find(category_id)
    if set&.root_account&.feature_enabled?(:granular_permissions_manage_groups)
      verify_authorized_action!(set.context, :manage_groups_add)
    else
      verify_authorized_action!(set.context, :manage_groups)
    end
    group = set.groups.build(name: input[:name], context: set.context)
    if group.save
      { group: }
    else
      errors_for(group)
    end
  rescue ActiveRecord::RecordNotFound
    raise GraphQL::ExecutionError, "not found"
  end
end
