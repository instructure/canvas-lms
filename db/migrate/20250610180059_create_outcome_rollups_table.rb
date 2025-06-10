# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

class CreateOutcomeRollupsTable < ActiveRecord::Migration[7.2]
  tag :predeploy

  def change
    create_table :outcome_rollups do |t|
      t.references :root_account, null: false, foreign_key: { to_table: :accounts }, index: false
      t.references :course, null: false, foreign_key: true, index: true
      t.references :user, null: false, foreign_key: true, index: true
      t.references :outcome, null: false, foreign_key: { to_table: :learning_outcomes }, index: true

      t.string :calculation_method, null: false
      t.check_constraint "calculation_method IN ('average', 'decaying_average', 'highest', 'latest', 'n_mastery', 'standard_decaying_average', 'weighted_average')", name: "outcome_rollups_calculation_method_check"
      t.float :aggregate_score, null: false
      t.timestamp :last_calculated_at, null: false

      t.string :workflow_state, default: "active", null: false
      t.check_constraint "workflow_state IN ('active', 'deleted')", name: "outcome_rollups_workflow_state_check"

      t.timestamps

      t.replica_identity_index
      t.index %i[course_id user_id outcome_id], unique: true, name: "index_outcome_rollups_on_course_user_outcome"
    end
  end
end
