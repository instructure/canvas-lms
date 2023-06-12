# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

module DataFixup::GranularPermissions::AddRoleOverridesForManageCoursesAdd
  # Find all roles with a base role type of %w[TeacherEnrollment DesignerEnrollment]
  # or %w[StudentEnrollment ObserverEnrollment] that also have a correlating root account
  # setting allowing teachers_can_create_courses? or students_can_create_courses?
  # Creates new role overrides for those roles based upon the prior scope, excluding site admin
  # Defaults to: [enabled: true, locked: false, applies_to_self: true, applies_to_descendants: true]
  class << self
    def run
      add_new_role_overrides(%w[TeacherEnrollment DesignerEnrollment])
      add_new_role_overrides(%w[StudentEnrollment ObserverEnrollment])
    end

    def add_new_role_overrides(base_role_types)
      roles = Role.where.not(workflow_state: "deleted").where(base_role_type: base_role_types)

      roles.each do |role|
        next if role.root_account.id == Setting.get("site_admin_account_id", "-1").to_i || role.root_account_id == 0

        root_account = role.root_account
        role_context = role.built_in? ? root_account : role.account
        scope = root_account.enrollments.active

        case base_role_types
        when %w[TeacherEnrollment DesignerEnrollment]
          if root_account.teachers_can_create_courses? && scope.where(type: base_role_types).exists?
            create_role_override(role, role_context)
          end
        when %w[StudentEnrollment ObserverEnrollment]
          if root_account.students_can_create_courses? && scope.where(type: base_role_types).exists?
            create_role_override(role, role_context)
          end
        end
      end
    end

    def create_role_override(role, role_context)
      if RoleOverride.where(permission: "manage_courses_add", context: role_context, role:)
                     .exists?
        return
      end

      RoleOverride.create!(
        context: role_context,
        permission: "manage_courses_add",
        role:,
        enabled: true
      )
    end
  end
end
