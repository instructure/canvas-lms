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

class DropOldSisStickyColumns < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    remove_column :abstract_courses, :sis_name
    remove_column :abstract_courses, :sis_course_code
    remove_column :accounts, :sis_name
    remove_column :course_sections, :sis_name
    remove_column :courses, :sis_name
    remove_column :courses, :sis_course_code
    remove_column :enrollment_terms, :sis_name
    remove_column :groups, :sis_name
    remove_column :users, :sis_name
  end

  def self.down
    add_column :users, :sis_name, :string
    add_column :groups, :sis_name, :string
    add_column :enrollment_terms, :sis_name, :string
    add_column :courses, :sis_name, :string
    add_column :courses, :sis_course_code, :string
    add_column :course_sections, :sis_name, :string
    add_column :accounts, :sis_name, :string
    add_column :abstract_courses, :sis_name, :string
  end
end
