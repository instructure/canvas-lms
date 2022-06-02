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

class CreateCoursePaces < ActiveRecord::Migration[6.0]
  tag :predeploy

  def up
    create_table :course_paces do |t|
      t.belongs_to :course, null: false, foreign_key: true
      t.references :course_section, null: true, index: false
      t.references :user, null: true, index: false
      t.string :workflow_state, default: "unpublished", null: false, limit: 255
      t.date :end_date
      t.boolean :exclude_weekends, null: false, default: true
      t.boolean :hard_end_dates, null: false, default: false
      t.timestamps
      t.datetime :published_at
      t.references :root_account, foreign_key: { to_table: :accounts }, null: false, index: false

      t.index [:course_id], unique: true, where: "course_section_id IS NULL AND user_id IS NULL AND workflow_state='active'", name: "course_paces_unique_primary_plan_index"
      t.index [:course_section_id], unique: true, where: "workflow_state='active'"
      t.index [:course_id, :user_id], unique: true, where: "workflow_state='active'"
    end

    add_replica_identity "CoursePace", :root_account_id, 0
  end

  def down
    drop_table :course_paces
  end
end
