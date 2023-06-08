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

module DataFixup::GranularPermissions::AddRoleOverridesForManageCoursesDelete
  # Find all role overrides with a permission of :manage_courses and :change_course_state
  # that share the same base role type. Use that as the new scoped relation for migrating
  # to the new granular role override permission :manage_courses_delete
  class << self
    def run(base_role_type: nil)
      roles_for_manage_courses_delete =
        Role
        .joins(:role_overrides)
        .where.not(workflow_state: "deleted")
        .where(base_role_type:)
        .where(
          "role_overrides.permission = ? OR role_overrides.permission = ?",
          "manage_courses",
          "change_course_state"
        )
        .distinct

      role_overrides =
        RoleOverride
        .where(
          permission: %w[manage_courses change_course_state],
          role_id: roles_for_manage_courses_delete
        )
        .index_by { |ro| [ro.role_id, ro.permission] }

      roles_for_manage_courses_delete.each do |role|
        manage_courses_ro = role_overrides[[role.id, "manage_courses"]]
        change_course_state_ro = role_overrides[[role.id, "change_course_state"]]

        if base_role_type == "AccountAdmin" &&
           (
             (manage_courses_ro && !manage_courses_ro.enabled) ||
               (change_course_state_ro && !change_course_state_ro.enabled)
           )
          check_locked_state_and_create_ro(manage_courses_ro, change_course_state_ro)
        elsif base_role_type == "AccountMembership" &&
              (manage_courses_ro&.enabled && change_course_state_ro&.enabled)
          check_locked_state_and_create_ro(manage_courses_ro, change_course_state_ro, enabled: true)
        else
          next
        end
      end
    end

    def check_locked_state_and_create_ro(manage_courses_ro, change_course_state_ro, enabled: false)
      if change_course_state_ro&.locked
        # use change_course_state role override if locked
        add_new_role_override(change_course_state_ro, enabled)
      else
        # otherwise use manage_courses role override for the copy unless nil
        add_new_role_override(manage_courses_ro || change_course_state_ro, enabled)
      end
    end

    def add_new_role_override(base_override, enabled)
      existing_ro =
        RoleOverride.where(
          permission: "manage_courses_delete",
          context: base_override.context,
          role: base_override.role
        ).exists?
      new_ro = RoleOverride.new
      new_ro.permission = "manage_courses_delete"
      attrs =
        base_override.attributes.slice(
          *%w[
            context_type
            context_id
            role_id
            locked
            enabled
            applies_to_self
            applies_to_descendants
            applies_to_env
            root_account_id
          ]
        )
      new_ro.assign_attributes(attrs)
      new_ro.enabled = enabled
      new_ro.save! unless existing_ro
    end
  end
end
