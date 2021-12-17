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
class AddHomeroomCourseColumns < ActiveRecord::Migration[6.0]
  tag :predeploy
  disable_ddl_transaction!

  def up
    add_column :courses, :homeroom_course, :boolean, if_not_exists: true, default: false, null: false
    add_column :courses, :sync_enrollments_from_homeroom, :boolean, if_not_exists: true, default: false, null: false
    add_reference :courses, :homeroom_course, if_not_exists: true, index: false, foreign_key: { to_table: :courses }

    add_index :courses, :homeroom_course, where: "homeroom_course", algorithm: :concurrently, if_not_exists: true
    add_index :courses, :sync_enrollments_from_homeroom, where: "sync_enrollments_from_homeroom", algorithm: :concurrently, if_not_exists: true
  end

  def down
    remove_column :courses, :homeroom_course
    remove_column :courses, :sync_enrollments_from_homeroom
    remove_column :courses, :homeroom_course_id
  end
end
