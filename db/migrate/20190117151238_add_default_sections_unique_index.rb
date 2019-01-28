#
# Copyright (C) 2019 - present Instructure, Inc.
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
class AddDefaultSectionsUniqueIndex < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!
  tag :postdeploy

  def up
    course_ids_to_fix = CourseSection.active.group(:course_id).where(:default_section => true).
      having("COUNT(*) > 1").pluck(:course_id)
    course_ids_to_fix.each do |course_id|
      CourseSection.where(:course_id => course_id, :default_section => true).
        order(:id).offset(1).update_all(:default_section => false)
    end
    add_index :course_sections, :course_id, :unique => true, :where => "default_section = 't' AND workflow_state <> 'deleted'",
      :name => "index_course_sections_unique_default_section"
  end

  def down
    remove_index :course_sections, :name => "index_course_sections_unique_default_section"
  end
end
