# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

module GroupPermissionHelper
  RIGHTS_MAP = {
    add: {
      collaborative: [:manage_groups_add],
      non_collaborative: [:manage_tags_add]
    },
    manage: {
      collaborative: [:manage_groups_manage],
      non_collaborative: [:manage_tags_manage]
    },
    delete: {
      collaborative: [:manage_groups_delete],
      non_collaborative: [:manage_tags_delete]
    },
    view: {
      collaborative: RoleOverride::GRANULAR_MANAGE_GROUPS_PERMISSIONS,
      non_collaborative: RoleOverride::GRANULAR_MANAGE_TAGS_PERMISSIONS
    }
  }.freeze

  # Checks the authorization policy for the given context using
  # the authorized_action method in app/controller/application_controller.rb
  #
  # If authorized, returns `true`; otherwise, renders unauthorized messages and returns `false`.
  #
  # This method is intended to be used within controller actions
  #
  # @argument context [Object] The context in which authorization is checked (e.g., a Group or Course object).
  #
  # @argument current_user [User] The user performing the action.
  #
  # @argument action_category [Symbol] The category of action (`:add`, `:manage`, `:delete`, `:view`).
  #
  # @argument non_collaborative [Boolean] Indicates whether the object is non-collaborative.
  #
  # @example_usage
  #     # In a controller action
  #     class GroupsController < ApplicationController
  #       include GroupPermissionHelper
  #
  #       def update
  #         @group = Group.find(params[:id])
  #         if check_group_authorization(@group.context, current_user, :manage, non_collaborative: false)
  #           # Proceed with update logic
  #           @group.update(group_params)
  #           redirect_to @group, notice: 'Group was successfully updated.'
  #         end
  #         # If unauthorized, appropriate render method is called within check_group_authorization
  #       end
  #     end
  #
  # @returns [Boolean]
  #   - Returns `true` if the `current_user` is authorized to perform the specified `action_category` within the given `context`.
  #   - If unauthorized, the method renders appropriate error messages and returns `false`.
  def check_group_authorization(context:, current_user:, action_category:, non_collaborative: nil)
    rights = determine_rights_for_type(action_category, non_collaborative)

    authorized_action(context, current_user, rights)
  end

  def check_group_context_rights(context:, current_user:, action_category:, non_collaborative: nil)
    rights = determine_rights_for_type(action_category, non_collaborative)

    context.grants_any_right?(current_user, *rights)
  end

  private

  def determine_rights_for_type(action_category, is_non_collaborative)
    permissions = RIGHTS_MAP[action_category]
    raise ArgumentError, "Unsupported action_category: #{action_category}" unless permissions

    is_non_collaborative ? permissions[:non_collaborative] : permissions[:collaborative]
  end
end
