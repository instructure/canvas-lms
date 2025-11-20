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

module DataFixup::RemoveRoleOverridesForNewPermission
  def self.run(base_permission, remove_permissions, skip_validation: false, skip_role_type: nil)
    unless skip_validation
      raise "#{base_permission} is not a valid permission" unless RoleOverride.permissions.key?(base_permission.to_sym)

      remove_permissions.each do |perm|
        raise "#{perm} is not a valid permission" unless RoleOverride.permissions.key?(perm.to_sym)
      end
    end

    base_rel = RoleOverride.where(permission: base_permission)
    base_rel = base_rel.joins(:role).where.not(roles: { base_role_type: skip_role_type }) if skip_role_type
    rel = RoleOverride.where(permission: remove_permissions, role_id: base_rel.select(:role_id))
    rel.in_batches.delete_all
  end
end
