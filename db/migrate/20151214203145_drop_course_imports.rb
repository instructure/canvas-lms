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

class DropCourseImports < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    drop_table :course_imports
  end

  def down
    create_table "course_imports" do |t|
      t.integer  "course_id", :limit => 8
      t.integer  "source_id", :limit => 8
      t.text     "added_item_codes"
      t.text     "log"
      t.string   "workflow_state"
      t.string   "import_type"
      t.integer  "progress"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end
end
