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

class Mutations::CreateGroupSet < Mutations::GroupSetBase
  include GraphQLHelpers::ContextFetcher
  include GroupPermissionHelper

  def resolve(input:)
    @current_user = current_user
    @context = context_fetcher(input, valid_contexts)

    if check_group_context_rights(
      context:,
      current_user: @current_user,
      action_category: :add,
      non_collaborative: input[:non_collaborative]
    )
      @group_category = context.group_categories.build

      # Add all desired settings to group category
      options = {
        name: input[:name],
        self_signup: input[:self_signup],
        auto_leader_type: input[:auto_leader_type],
        group_limit: input[:group_limit],
        non_collaborative: input[:non_collaborative],
        create_group_count: get_group_count(input[:create_group_count]),
        create_group_member_count: input[:create_group_member_count],
        group_by_section: input[:group_by_section],
        enable_auto_leader: input[:enable_auto_leader],
        enable_self_signup: input[:enable_self_signup],
        restrict_self_signup: input[:restrict_self_signup],
        assign_async: input[:assign_async],
        assign_unassigned_members: input[:assign_unassigned_members],
      }

      populate_group_category(options)
    else
      raise GraphQL::ExecutionError, "Insufficient permissions to create group set"
    end

    { group_set: @group_category }
  end

  # Private
  def populate_group_category(options)
    @group_category = GroupCategories::ParamsPolicy.new(@group_category, @context).populate_with(options)

    SubmissionLifecycleManager.with_executing_user(@current_user) do
      unless @group_category.save
        raise GraphQL::ExecutionError, "Unable to create group set"
      end
    end
  end

  def get_group_count(count)
    if count && count > 0
      [count, Setting.get("max_groups_in_new_category", "200").to_i].min
    else
      nil
    end
  end

  # The purpose of this method is to generate a list of valid contexts for the group set
  # based on the values in Types::GroupSetContextType
  # The context_fetcher requires a list of contexts that are capitalized on the first letter
  def valid_contexts
    Types::GroupSetContextType.values.values.map(&:value)
  end
end
