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

class GenericSisStickinessRefactorColumns < ActiveRecord::Migration[4.2]
  tag :predeploy


  def self.up
    add_column :abstract_courses, :stuck_sis_fields, :text
    add_column :accounts, :stuck_sis_fields, :text
    add_column :courses, :stuck_sis_fields, :text
    add_column :groups, :stuck_sis_fields, :text
    add_column :course_sections, :stuck_sis_fields, :text
    add_column :enrollment_terms, :stuck_sis_fields, :text
    add_column :users, :stuck_sis_fields, :text
  end

  def self.down
    drop_column :users, :stuck_sis_fields
    drop_column :enrollment_terms, :stuck_sis_fields
    drop_column :course_sections, :stuck_sis_fields
    drop_column :groups, :stuck_sis_fields
    drop_column :courses, :stuck_sis_fields
    drop_column :accounts, :stuck_sis_fields
    drop_column :abstract_courses, :stuck_sis_fields
  end

end
