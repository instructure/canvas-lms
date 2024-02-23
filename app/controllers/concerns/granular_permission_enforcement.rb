# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

module GranularPermissionEnforcement
  # Checks the authorization policy for the given object using
  # the vendor/plugins/adheres_to_policy plugin.  If authorized,
  # returns true, otherwise renders unauthorized messages and returns
  # false.
  #
  # @argument object Object(initialized)
  #   The object to check rights against.
  # @argument overrides Array(:symbol, ...)
  #   An array of default permission overrides.
  # @argument actions Hash(:symbol => Array(:symbol, ...), ...)
  #   A hash of controller actions and their associated granular permission checks
  #
  # To be used as follows:
  # enforce_granular_permissions(
  #   @context,
  #   overrides: [:manage_content],
  #   actions: {
  #     index: RoleOverride::GRANULAR_MANAGE_COURSE_CONTENT_PERMISSIONS,
  #     show: RoleOverride::GRANULAR_MANAGE_COURSE_CONTENT_PERMISSIONS,
  #     new: RoleOverride::GRANULAR_MANAGE_COURSE_CONTENT_PERMISSIONS,
  #     create: [:manage_course_content_add],
  #     update: [:manage_course_content_edit],
  #     destroy: [:manage_course_content_delete]
  #   }
  # )
  def enforce_granular_permissions(object, overrides:, actions:)
    if actions[action_name.to_sym].nil?
      raise "Missing current controller action: #{action_name} in provided actions"
    end

    permissions = overrides.concat(actions[action_name.to_sym])
    authorized_action(object, @current_user, permissions)
  end

  private_instance_methods :enforce_granular_permissions
end
