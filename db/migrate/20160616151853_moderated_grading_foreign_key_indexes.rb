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

class ModeratedGradingForeignKeyIndexes < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def change
    add_index :submission_comments, :provisional_grade_id, where: "provisional_grade_id IS NOT NULL", algorithm: :concurrently
    add_index :moderated_grading_provisional_grades, :source_provisional_grade_id, name: 'index_provisional_grades_on_source_grade', where: "source_provisional_grade_id IS NOT NULL", algorithm: :concurrently
    add_index :moderated_grading_selections, :selected_provisional_grade_id, name: 'index_moderated_grading_selections_on_selected_grade', where: "selected_provisional_grade_id IS NOT NULL", algorithm: :concurrently
    # this index is useless; the index on [assignment_id, student_id] already covers it
    remove_index :moderated_grading_selections, column: :assignment_id
    add_index :moderated_grading_selections, :student_id, algorithm: :concurrently
  end
end
