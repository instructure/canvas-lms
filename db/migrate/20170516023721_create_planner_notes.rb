# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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
#
class CreatePlannerNotes < ActiveRecord::Migration[4.2]
  tag :predeploy
  def change
    create_table :planner_notes do |t|
      t.datetime :todo_date, null: false
      t.string :title, null: false
      t.text :details
      t.integer :user_id, null: false, limit: 8
      t.integer :course_id, limit: 8
      t.string :workflow_state, null: false
      t.timestamps null: false
    end
    add_foreign_key :planner_notes, :users
    add_index :planner_notes, :user_id
  end
end
