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

class IndexCourseSectionsNonxlistCourse < ActiveRecord::Migration[4.2]
  tag :predeploy
  disable_ddl_transaction!

  def self.up
    add_index :course_sections, [:nonxlist_course_id], :name => "index_course_sections_on_nonxlist_course", :algorithm => :concurrently, :where => "nonxlist_course_id IS NOT NULL"
  end

  def self.down
    remove_index :course_sections, "index_course_sections_on_nonxlist_course"
  end
end
