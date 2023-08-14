# frozen_string_literal: true

#
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

module DataFixup::AddRoleOverridesForPermissionCombination
  # run when we add a new permission for a behavior that formerly required *multiple* permissions.
  # if overrides and/or the permission's `true_for` clause grant all of `old_permissions`, a role override
  # will be created that grants `new_permission`. if any of `old_permissions` are denied, `new_permission`
  # will also be denied. optionally specify `base_role_types` to limit the roles to update (such as when
  # `old_permissions` apply to teachers but `new_permission` is only for account admins).
  # note that if role overrides for `new_permission` already exist for a context and role, none will be created.
  def self.run(old_permissions:, new_permission:, base_role_types: [])
    permissions = [*old_permissions, new_permission].map(&:to_sym)
    permissions.each do |perm|
      raise ArgumentError, "#{perm} is not a valid permission" unless RoleOverride.permissions.key?(perm)
    end

    role_scope = Role
                 .where.not(workflow_state: "deleted")
                 .where("EXISTS(SELECT 1 FROM #{RoleOverride.quoted_table_name} ro WHERE roles.id=ro.role_id AND ro.permission IN (?))", old_permissions)
    if base_role_types.any?
      role_scope = role_scope.where(base_role_type: base_role_types)
    end

    role_scope.find_each do |role|
      role.role_overrides
          .where(permission: permissions)
          .group_by(&:context)
          .each do |context, overrides|
        new_overrides, old_overrides = overrides.partition { |ro| ro.permission == new_permission.to_s }
        next if new_overrides.any? || old_overrides.empty?

        all_enabled = old_permissions.all? do |permission|
          override = old_overrides.find { |ro| ro.permission == permission.to_s }
          if override
            override.enabled
          else
            RoleOverride.permissions[permission][:true_for].include?(role.base_role_type)
          end
        end

        if all_enabled
          create_role_override(context:, role:, new_permission:, enabled: true, prototype_role_overrides: old_overrides)
        elsif old_overrides.any? { |ro| !ro.enabled }
          create_role_override(context:, role:, new_permission:, enabled: false, prototype_role_overrides: old_overrides)
        end
      end
    end
  end

  def self.create_role_override(context:, role:, new_permission:, enabled:, prototype_role_overrides:)
    ro = role.role_overrides.build(permission: new_permission, context:, enabled:)
    ro.locked = prototype_role_overrides.any?(&:locked)
    ro.applies_to_self = prototype_role_overrides.all?(&:applies_to_self)
    ro.applies_to_descendants = prototype_role_overrides.all?(&:applies_to_descendants)
    return unless ro.applies_to_self || ro.applies_to_descendants

    ro.save!
  end
end
