# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

class MoreGranularAdminUsersPermissions < ActiveRecord::Migration[5.2]
  tag :postdeploy

  def up
    DataFixup::AddRoleOverridesForNewPermission.run(:manage_admin_users, :allow_course_admin_actions)
    DataFixup::AddRoleOverridesForNewPermission.run(:manage_admin_users, :add_teacher_to_course)
    DataFixup::AddRoleOverridesForNewPermission.run(:manage_admin_users, :add_ta_to_course)
    DataFixup::AddRoleOverridesForNewPermission.run(:manage_admin_users, :add_observer_to_course)
    DataFixup::AddRoleOverridesForNewPermission.run(:manage_admin_users, :add_designer_to_course)
    DataFixup::AddRoleOverridesForNewPermission.run(:manage_admin_users, :remove_teacher_from_course)
    DataFixup::AddRoleOverridesForNewPermission.run(:manage_admin_users, :remove_ta_from_course)
    DataFixup::AddRoleOverridesForNewPermission.run(:manage_admin_users, :remove_observer_from_course)
    DataFixup::AddRoleOverridesForNewPermission.run(:manage_admin_users, :remove_designer_from_course)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
