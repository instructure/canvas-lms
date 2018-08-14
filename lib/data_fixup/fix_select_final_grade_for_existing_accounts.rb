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

module DataFixup
  module FixSelectFinalGradeForExistingAccounts
    def self.run
      # moderate_grades and select_final_grades are available to the same
      # roles, but moderate_grades defaults to disabled for ta roles while
      # select_final_grade defaults to true. That is the only difference.
      # There are three cases we want to accomplish: non-ta, ta, ta-based
      all_moderate_grades_overrides = RoleOverride.where(permission: 'moderate_grades')
      all_select_final_grade_overrides = RoleOverride.where(permission: 'select_final_grade')
      all_ta_and_related_roles = Role.where(base_role_type: 'TaEnrollment')
      site_admin = Account.site_admin

      # The case where moderate_grades RoleOverrides exist for non-ta roles.
      all_moderate_grades_overrides.where(enabled: false).find_in_batches do |moderate_overrides|
        new_role_overrides = []
        moderate_overrides.each do |moderate_override|
          next if all_select_final_grade_overrides.exists?(
            role_id: moderate_override.role_id,
            context_id: moderate_override.context_id
          )
          # We take care of ta roles in the Account.find_each block.
          next if all_ta_and_related_roles.exists?(id: moderate_override.role_id)

          new_role_overrides << {
            permission: 'select_final_grade',
            context_id: moderate_override.context_id,
            context_type: moderate_override.context_type,
            enabled: moderate_override.enabled,
            locked: moderate_override.locked,
            role_id: moderate_override.role_id
          }
        end

        RoleOverride.bulk_insert(new_role_overrides)
      end

      Account.find_in_batches do |accounts|
        new_role_overrides = []
        accounts.each do |account|
          # Setting a role override on SiteAdmin will trickle down effects to
          # other accounts.
          next if account == site_admin
          # Create a RoleOverride for ta/ta-based roles only if either a
          # moderate_grades one does not exist (so disabled), or if one exists
          # exists but is disabled.
          moderate_overrides = all_moderate_grades_overrides.where(context_id: account.id, enabled: true)
          select_overrides = all_select_final_grade_overrides.where(context_id: account.id)
          # The default TaEnrollment role belongs to no specific account, so we
          # grab it by name here.
          ta_roles = all_ta_and_related_roles.where('account_id=? OR name=?', account.id, 'TaEnrollment')

          ta_roles.each do |ta_role|
            # Skip if a RoleOverride already exists for this role, or if a
            # moderate_grades RoleOverride exists and is enabled.
            next if select_overrides.exists?(role_id: ta_role.id)
            next if moderate_overrides.exists?(role_id: ta_role.id)

            new_role_overrides << {
              permission: 'select_final_grade',
              context_id: account.id,
              context_type: 'Account',
              enabled: false,
              locked: false,
              role_id: ta_role.id
            }
          end
        end
        RoleOverride.bulk_insert(new_role_overrides)
      end
    end
  end
end
