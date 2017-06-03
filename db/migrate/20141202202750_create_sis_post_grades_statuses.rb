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

class CreateSisPostGradesStatuses < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    create_table :sis_post_grades_statuses do |t|
      t.integer :course_id, :null => false, :limit => 8
      t.integer :course_section_id, :limit => 8
      t.integer :user_id, :limit => 8
      t.string :status, :null => false
      t.string :message, :null => false
      t.datetime :grades_posted_at, :null => false
      t.timestamps null: true
    end

    add_index :sis_post_grades_statuses, :course_id
    add_index :sis_post_grades_statuses, :course_section_id
    add_index :sis_post_grades_statuses, :user_id
    add_foreign_key :sis_post_grades_statuses, :courses
    add_foreign_key :sis_post_grades_statuses, :course_sections
    add_foreign_key :sis_post_grades_statuses, :users
  end

end
