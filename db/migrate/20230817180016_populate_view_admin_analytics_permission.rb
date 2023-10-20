# frozen_string_literal: true

# Copyright (C) 2023 - present Instructure, Inc.
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
class PopulateViewAdminAnalyticsPermission < ActiveRecord::Migration[7.0]
  tag :postdeploy

  def up
    if RoleOverride.permissions.key?(:view_analytics)
      # the Admin Analytics tool formerly required both of these permissions,
      # even though :view_analytics is not part of core Canvas...
      DataFixup::AddRoleOverridesForPermissionCombination.run(
        old_permissions: %i[view_analytics view_all_grades],
        new_permission: :view_admin_analytics,
        base_role_types: %i[AccountAdmin AccountMembership]
      )
    else
      # ...so if the legacy analytics plugin isn't installed, nobody has the requisite permissions.
      # fall back on granting it by default only to admins who need it to masquerade
      DataFixup::AddRoleOverridesForNewPermission.run(:become_user, :view_admin_analytics)
    end
  end

  def down; end
end
