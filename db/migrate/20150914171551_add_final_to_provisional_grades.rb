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

class AddFinalToProvisionalGrades < ActiveRecord::Migration[4.2]
  tag :predeploy

  def up
    add_column :moderated_grading_provisional_grades, :final, :boolean, :null => false, :default => false

    add_index :moderated_grading_provisional_grades,
      [:submission_id],
      :unique => true,
      :where => "final = TRUE",
      :name => :idx_mg_provisional_grades_unique_submission_when_final

    remove_index :moderated_grading_provisional_grades, :name => :idx_mg_provisional_grades_unique_submission_scorer
    add_index :moderated_grading_provisional_grades,
      [:submission_id, :scorer_id],
      :unique => true,
      :name => :idx_mg_provisional_grades_unique_sub_scorer_when_not_final,
      :where => "final = FALSE"
  end

  def down
    remove_index :moderated_grading_provisional_grades, :name => :idx_mg_provisional_grades_unique_submission_when_final
    remove_index :moderated_grading_provisional_grades, :name => :idx_mg_provisional_grades_unique_sub_scorer_when_not_final
    ModeratedGrading::ProvisionalGrade.where(:final => false,
      :scorer_id => ModeratedGrading::ProvisionalGrade.where(:final => true).select(:scorer_id)).delete_all # resolve the unique index
    remove_column :moderated_grading_provisional_grades, :final

    add_index :moderated_grading_provisional_grades,
      [:submission_id, :scorer_id],
      unique: true,
      name: :idx_mg_provisional_grades_unique_submission_scorer
  end
end
