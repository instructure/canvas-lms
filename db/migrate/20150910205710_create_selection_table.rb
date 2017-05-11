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

class CreateSelectionTable < ActiveRecord::Migration[4.2]
  tag :predeploy

  def up
    create_table :moderated_grading_selections do |t|
      t.integer :assignment_id,                 limit: 8, null: false
      t.integer :student_id,                    limit: 8, null: false
      t.integer :selected_provisional_grade_id, limit: 8, null: true

      t.timestamps null: false
    end

    add_index :moderated_grading_selections, :assignment_id
    add_index :moderated_grading_selections,
              [:assignment_id, :student_id],
              unique: true,
              name: :idx_mg_selections_unique_on_assignment_and_student
    add_foreign_key :moderated_grading_selections, :assignments
    add_foreign_key :moderated_grading_selections, :users, column: :student_id
    add_foreign_key :moderated_grading_selections, :moderated_grading_provisional_grades, column: :selected_provisional_grade_id
  end

  def down
    drop_table :moderated_grading_selections
  end
end
