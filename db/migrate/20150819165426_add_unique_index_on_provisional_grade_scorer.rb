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

class AddUniqueIndexOnProvisionalGradeScorer < ActiveRecord::Migration[4.2]
  tag :predeploy

  def up
    # remove constraints on position, which will be dropped in a postdeploy migration
    change_column_null :moderated_grading_provisional_grades, :position, true
    remove_index :moderated_grading_provisional_grades, :name => :idx_mg_provisional_grades_unique_submission_position

    # keep only the newest provisional grade for each scorer/submission pair, then add the unique constraint
    ModeratedGrading::ProvisionalGrade.where("id NOT IN (SELECT * FROM (SELECT MAX(id) FROM #{ModeratedGrading::ProvisionalGrade.quoted_table_name} GROUP BY submission_id, scorer_id) x)").delete_all
    add_index :moderated_grading_provisional_grades,
              [:submission_id, :scorer_id],
              unique: true,
              name: :idx_mg_provisional_grades_unique_submission_scorer
  end

  def down
    remove_index :moderated_grading_provisional_grades, :name => :idx_mg_provisional_grades_unique_submission_scorer
  end
end
