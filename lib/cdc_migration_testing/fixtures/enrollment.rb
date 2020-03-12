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

module CdcFixtures
  def self.create_enrollment
    Enrollment.new({
      id: 1,
      user_id: 1,
      course_id: 1,
      type: 'StudentEnrollment',
      workflow_state: 'active',
      course_section_id: 1,
      root_account_id: 1,
      limit_privileges_to_course_section: false,
      role_id: 1
    })
  end
end
