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

  argument :group_set_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("GroupSet")
  argument :name, String, required: true
  argument :non_collaborative, Boolean, required: false, default_value: false

  field :group, Types::GroupType, null: true

  def resolve(input:)
    category_id = GraphQLHelpers.parse_relay_or_legacy_id(input[:group_set_id], "GroupSet")
    set = GroupCategory.find(category_id)
    account = (set.context_type == "Account") ? set.context : set.context&.account
    verify_authorized_action!(set.context, :manage_groups_add)

    if input[:non_collaborative]
      if account&.allow_assign_to_differentiation_tags?
        raise GraphQL::ExecutionError, "insufficient permissions to create non-collaborative groups" unless set.context&.grants_right?(current_user, session, :manage_tags_add)
      else
        raise GraphQL::ExecutionError, "cannot create non-collaborative groups when the differentiation tags feature flag is disabled"
      end
    elsif set.non_collaborative
      raise GraphQL::ExecutionError, "cannot create collaborative groups in a non-collaborative group set"
    end

    group = set.groups.build(name: input[:name], context: set.context, non_collaborative: input[:non_collaborative])

    if group.save
      { group: }
    else
      errors_for(group)
    end
  rescue ActiveRecord::RecordNotFound
    raise GraphQL::ExecutionError, "not found"
  end
end
