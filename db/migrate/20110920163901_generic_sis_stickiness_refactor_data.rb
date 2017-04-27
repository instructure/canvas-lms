#
# Copyright (C) 2011 - present Instructure, Inc.
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

class GenericSisStickinessRefactorData < ActiveRecord::Migration[4.2]
  tag :predeploy


  def self.up
    update <<-SQL
      UPDATE #{AbstractCourse.quoted_table_name} SET stuck_sis_fields =
          (CASE WHEN sis_name <> name THEN
            (CASE WHEN sis_course_code <> short_name THEN
              'name,short_name'
            ELSE
              'name'
            END)
          WHEN sis_course_code <> short_name THEN
            'short_name'
          ELSE
            NULL
          END);
    SQL
    update <<-SQL
      UPDATE #{Course.quoted_table_name} SET stuck_sis_fields =
          (CASE WHEN sis_name <> name THEN
            (CASE WHEN sis_course_code <> course_code THEN
              'name,course_code'
            ELSE
              'name'
            END)
          WHEN sis_course_code <> course_code THEN
            'course_code'
          ELSE
            NULL
          END);
    SQL
    update <<-SQL
      UPDATE #{CourseSection.quoted_table_name} SET stuck_sis_fields =
          (CASE WHEN sis_name <> name THEN
            (CASE WHEN sticky_xlist THEN
              'course_id,name'
            ELSE
              'name'
            END)
          WHEN sticky_xlist THEN
            'course_id'
          ELSE
            NULL
          END);
    SQL
    Account.where("sis_name<>name").update_all(stuck_sis_fields: 'name')
    Group.where("sis_name<>name").update_all(stuck_sis_fields: 'name')
    EnrollmentTerm.where("sis_name<>name").update_all(stuck_sis_fields: 'name')
    User.where("sis_name<>name").update_all(stuck_sis_fields: 'name')
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end

end
