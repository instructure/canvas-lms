# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

module DataFixup::AddRoleOverridesForNewPermission
  # any time we add a new permission, we should run this to populate the role overrides for
  # custom roles lest there be any rude surprises when the custom roles no longer behave as expected
  # (for instance if a custom account admin has :manage_admin_users, they will
  # suddenly no longer be able to add account admins anymore until this is run)

  def self.run(base_permission, new_permission, skip_validation: false, base_role_type: nil)
    unless skip_validation
      [base_permission, new_permission].each do |perm|
        raise "#{perm} is not a valid permission" unless RoleOverride.permissions.key?(perm.to_sym)
      end
    end

    rel = RoleOverride.where(permission: base_permission)
    rel = rel.joins(:role).where(roles: { base_role_type: }) if base_role_type
    rel.find_in_batches do |base_overrides|
      # just in case
      new_overrides = RoleOverride.where(permission: new_permission, context_id: base_overrides.map(&:context_id))

      base_overrides.each do |ro|
        next if new_overrides.detect { |nro| nro.context_id == ro.context_id && nro.context_type == ro.context_type && nro.role_id == ro.role_id }

        new_ro = RoleOverride.new
        new_ro.permission = new_permission
        attrs = ro.attributes.slice(*%w[context_type context_id role_id locked enabled applies_to_self applies_to_descendants applies_to_env root_account_id])
        new_ro.assign_attributes(attrs)
        new_ro.save!
      end
    end
  end
end
