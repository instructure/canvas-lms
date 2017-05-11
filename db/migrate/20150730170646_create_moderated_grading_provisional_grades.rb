#
# Copyright (C) 2015 - present Instructure, Inc.
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

class CreateModeratedGradingProvisionalGrades < ActiveRecord::Migration[4.2]
  tag :predeploy

  def up
    create_table :moderated_grading_provisional_grades do |t|
      t.string     :grade
      t.float      :score
      t.timestamp  :graded_at
      t.integer    :position,   null: false, limit: 8
      t.references :scorer,     null: false, limit: 8
      t.references :submission, null: false, limit: 8

      t.timestamps null: true
    end

    add_index :moderated_grading_provisional_grades, :submission_id
    add_index :moderated_grading_provisional_grades,
              [:submission_id, :position],
              unique: true,
              name: :idx_mg_provisional_grades_unique_submission_position
    add_foreign_key :moderated_grading_provisional_grades, :submissions
    add_foreign_key :moderated_grading_provisional_grades,
                    :users,
                    column: :scorer_id
  end

  def down
    drop_table :moderated_grading_provisional_grades
  end
end
