#
# Copyright (C) 2016 - present Instructure, Inc.
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

class CreateMasterTemplates < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    create_table :master_courses_master_templates do |t|
      t.integer :course_id, limit: 8, null: false
      t.boolean :full_course, null: false, default: true # we may not ever get around to allowing selective collection sets out but just in case
      t.string :workflow_state
      t.timestamps null: false
    end

    add_foreign_key :master_courses_master_templates, :courses
    add_index :master_courses_master_templates, :course_id
  end
end
