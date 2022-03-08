# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

class RemovePacePlans < ActiveRecord::Migration[6.0]
  tag :postdeploy

  def up
    drop_table :pace_plan_module_items
    drop_table :pace_plans
  end

  def down
    create_table :pace_plans do |t|
      t.belongs_to :course, null: false, foreign_key: true
      t.references :course_section, null: true, index: false
      t.references :user, null: true, index: false
      t.string :workflow_state, default: "unpublished", null: false, limit: 255
      t.date :end_date
      t.boolean :exclude_weekends, null: false, default: true
      t.boolean :hard_end_dates, null: false, default: false
      t.timestamps
      t.datetime :published_at
      t.references :root_account, foreign_key: { to_table: "accounts" }, limit: 8, null: false

      t.index [:course_id], unique: true, where: "course_section_id IS NULL AND user_id IS NULL AND workflow_state='active'", name: "pace_plans_unique_primary_plan_index"
      t.index [:course_section_id], unique: true, where: "workflow_state='active'"
      t.index [:course_id, :user_id], unique: true, where: "workflow_state='active'"
    end
    add_replica_identity("PacePlan", :root_account_id, 0) if defined?(PacePlan)

    create_table :pace_plan_module_items do |t|
      t.belongs_to :pace_plans, foreign_key: true, index: true
      t.integer :duration, null: false, default: 0
      t.references :module_item, foreign_key: { to_table: "content_tags" }
      t.references :root_account, foreign_key: { to_table: "accounts" }, limit: 8, null: false
    end
    add_replica_identity("PacePlan", :root_account_id, 0) if defined?(PacePlanModuleItem)
  end
end
