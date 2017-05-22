#
# Copyright (C) 2012 - present Instructure, Inc.
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

class FixDefaultLimitPrivilegesToCourseSection < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    Enrollment.find_ids_in_ranges do |(start_id, end_id)|
      Enrollment.where("type IN ('StudentEnrollment', 'ObserverEnrollment', 'StudentViewEnrollment', 'DesignerEnrollment') AND id>=? AND id <=?", start_id, end_id).update_all(:limit_privileges_to_course_section => false)
      Enrollment.where("type IN ('TeacherEnrollment', 'TaEnrollment') AND limit_privileges_to_course_section IS NULL AND id>=? AND id <=?", start_id, end_id).update_all(:limit_privileges_to_course_section => false)
    end
  end

  def self.down
  end
end
