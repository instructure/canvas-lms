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

class AddAssignmentGroupIdToScores < ActiveRecord::Migration[5.0]
  tag :predeploy
  disable_ddl_transaction!

  def change
    add_belongs_to :scores, :assignment_group, limit: 8, null: true
    add_column :scores, :course_score, :boolean, if_not_exists: true

    change_column_default :scores, :course_score, from: nil, to: false

    add_index :scores,
              :enrollment_id,
              algorithm: :concurrently,
              name: :index_enrollment_scores,
              if_not_exists: true

    add_index :scores,
              %i[enrollment_id grading_period_id],
              unique: true,
              where: "grading_period_id IS NOT NULL",
              algorithm: :concurrently,
              name: :index_grading_period_scores,
              if_not_exists: true

    add_index :scores,
              %i[enrollment_id assignment_group_id],
              unique: true,
              where: "assignment_group_id IS NOT NULL",
              algorithm: :concurrently,
              name: :index_assignment_group_scores,
              if_not_exists: true

    add_index :scores,
              :enrollment_id,
              unique: true,
              where: "course_score", # course_score is already boolean
              algorithm: :concurrently,
              name: :index_course_scores,
              if_not_exists: true

    remove_index :scores,
                 column: :enrollment_id,
                 name: :index_scores_on_enrollment_id,
                 if_exists: true

    remove_index :scores,
                 column: [:enrollment_id, :grading_period_id],
                 name: :index_scores_on_enrollment_id_and_grading_period_id,
                 if_exists: true

    reversible do |direction|
      direction.down { DataFixup::DeleteScoresForAssignmentGroups.run }
    end
  end
end
