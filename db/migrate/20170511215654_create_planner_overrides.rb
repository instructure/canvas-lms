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

class CreatePlannerOverrides < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    create_table :planner_overrides do |t|
      t.string :plannable_type, null: false
      t.integer :plannable_id, limit: 8, null: false
      t.integer :user_id, limit: 8, null: false
      t.string :workflow_state
      t.boolean :visible, null: false, default: true
      t.datetime :deleted_at

      t.timestamps null: false
    end

    add_index :planner_overrides, [:plannable_type, :plannable_id, :user_id], unique: true, name: 'index_planner_overrides_on_plannable_and_user'
    add_foreign_key :planner_overrides, :users
  end

  def self.down
    drop_table :planner_overrides
  end
end
