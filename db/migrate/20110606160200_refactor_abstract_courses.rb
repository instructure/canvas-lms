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

class RefactorAbstractCourses < ActiveRecord::Migration[4.2]
  tag :predeploy


  def self.up
    remove_column :course_sections, :abstract_course_id
    AbstractCourse.delete_all
    remove_index :abstract_courses, :department_id
    remove_column :abstract_courses, :college_id
    rename_column :abstract_courses, :department_id, :account_id
    rename_column :abstract_courses, :course_code, :short_name
    add_column :abstract_courses, :enrollment_term_id, :integer, :limit => 8
    add_column :abstract_courses, :sis_course_code, :string
    add_column :abstract_courses, :sis_name, :string
    add_column :abstract_courses, :workflow_state, :string
    add_index :abstract_courses, :account_id
    add_index :abstract_courses, :enrollment_term_id
  end

  def self.down
    [:enrollment_term_id, :sis_course_code, :sis_name, :workflow_state].each do |column|
      remove_column :abstract_courses, column
    end
    remove_index :abstract_courses, :account_id
    rename_column :abstract_courses, :account_id, :department_id
    add_index :abstract_courses, :department_id
    rename_column :abstract_courses, :short_name, :course_code
    add_column :abstract_courses, :college_id, :integer, :limit => 8
    add_index :abstract_courses, :college_id
    add_column :course_sections, :abstract_course_id, :integer, :limit => 8
    add_index :course_sections, :abstract_course_id
  end

end
