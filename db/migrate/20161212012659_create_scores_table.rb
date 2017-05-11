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

class CreateScoresTable < ActiveRecord::Migration[4.2]
  tag :predeploy

  def up
    create_table :scores do |t|
      t.integer :enrollment_id, limit: 8, null: false
      t.integer :grading_period_id, limit: 8
      t.string  :workflow_state, default: :active, null: false, limit: 255
      t.float   :current_score
      t.float   :final_score
      t.timestamps null: true
    end

    add_foreign_key :scores, :enrollments
    add_foreign_key :scores, :grading_periods

    add_index :scores, [:enrollment_id, :grading_period_id], unique: true
  end

  def down
    drop_table :scores
  end
end
