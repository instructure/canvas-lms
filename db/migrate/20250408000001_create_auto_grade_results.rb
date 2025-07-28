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

class CreateAutoGradeResults < ActiveRecord::Migration[7.0]
  tag :predeploy

  def change
    create_table :auto_grade_results do |t|
      t.index [:submission_id, :attempt], unique: true
      t.references :submission, null: false, foreign_key: true, index: false
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false
      t.integer :attempt, null: false, check: { constraint_name: "chk_attempt_positive", expression: "attempt > 0" }
      t.jsonb :grade_data, null: false
      t.string :error_message, default: nil, limit: 255
      t.integer :grading_attempts, null: false, default: 0, check: { constraint_name: "chk_grading_attempts_positive", expression: "grading_attempts > 0" }
      t.timestamps
      t.replica_identity_index
    end
  end
end
