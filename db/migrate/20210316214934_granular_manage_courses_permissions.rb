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
#
class GranularManageCoursesPermissions < ActiveRecord::Migration[6.0]
  tag :postdeploy

  def change
    DataFixup::GranularPermissions::AddRoleOverridesForManageCoursesDelete.run(
      base_role_type: 'AccountAdmin'
    )
    DataFixup::GranularPermissions::AddRoleOverridesForManageCoursesDelete.run(
      base_role_type: 'AccountMembership'
    )
    DataFixup::AddRoleOverridesForNewPermission.run(
      :change_course_state,
      :manage_courses_delete,
      base_role_type: 'TeacherEnrollment'
    )
    DataFixup::AddRoleOverridesForNewPermission.run(
      :change_course_state,
      :manage_courses_delete,
      base_role_type: 'DesignerEnrollment'
    )
    DataFixup::GranularPermissions::AddRoleOverridesForManageCoursesAdd.run
    DataFixup::AddRoleOverridesForNewPermission.run(:manage_courses, :manage_courses_admin)
    DataFixup::AddRoleOverridesForNewPermission.run(:manage_courses, :manage_courses_add)
    DataFixup::AddRoleOverridesForNewPermission.run(:change_course_state, :manage_courses_publish)
    DataFixup::AddRoleOverridesForNewPermission.run(:change_course_state, :manage_courses_conclude)
  end
end
