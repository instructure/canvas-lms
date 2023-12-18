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
#

module DataFixup::GranularPermissions::AddRoleOverridesToOutcomesServiceUser
  def self.run
    roles_with_missing_perms = Role.joins("CROSS JOIN unnest('{
                                              manage_rubrics,
                                              view_all_grades,
                                              read_global_outcomes,
                                              read_outcomes,
                                              read_course_content,
                                              read_course_list
                                            }'::varchar[]) AS need_permissions
                                            LEFT JOIN #{RoleOverride.quoted_table_name}
                                              ON role_overrides.role_id = roles.id AND role_overrides.permission = need_permissions")
                                   .where(name: "Outcomes Service", base_role_type: "AccountMembership", role_overrides: { role_id: nil })
                                   .group(:id)
                                   .select(:id, :account_id, :root_account_id, "array_agg(need_permissions) AS missing_perms")

    loop do
      batch = roles_with_missing_perms.limit(1000)
      batch.each do |role|
        role["missing_perms"].each do |perm|
          role.role_overrides.create!(permission: perm, context_type: "Account", context_id: role.account_id || role.root_account_id)
        end
      end

      break if batch.length < 1000
    end
  end
end
