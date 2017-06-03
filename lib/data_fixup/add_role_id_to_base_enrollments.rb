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

module DataFixup::AddRoleIdToBaseEnrollments
  def self.run
    Role.built_in_course_roles.each do |base_role|
      while Enrollment.where("role_id IS NULL AND type = ?", base_role.name).limit(1000).update_all(:role_id => base_role.id) > 0; end
    end
    student_role = Role.get_built_in_role("StudentEnrollment")
    while Enrollment.where("role_id IS NULL AND type = ?", "StudentViewEnrollment").limit(1000).update_all(:role_id => student_role.id) > 0; end
  end
end