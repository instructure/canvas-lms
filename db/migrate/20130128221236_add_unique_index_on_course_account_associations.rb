#
# Copyright (C) 2013 - present Instructure, Inc.
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

class AddUniqueIndexOnCourseAccountAssociations < ActiveRecord::Migration[4.2]
  tag :predeploy
  disable_ddl_transaction!

  def self.up
    # clean up any dups first
    course_ids = CourseAccountAssociation.
        select(:course_id).
        distinct.
        group(:course_id, :course_section_id, :account_id).
        having("COUNT(*)>1").
        map(&:course_id)
    Course.update_account_associations(course_ids)

    add_index :course_account_associations, [:course_id, :course_section_id, :account_id], :unique => true, :algorithm => :concurrently, :name => 'index_caa_on_course_id_and_section_id_and_account_id'
    remove_index :course_account_associations, :course_id
  end

  def self.down
    add_index :course_account_associations, :course_id, :algorithm => :concurrently
    remove_index :course_account_associations, 'index_caa_on_course_id_and_section_id_and_account_id'
  end
end
