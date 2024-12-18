# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

class CreateRubricAssessmentImports < ActiveRecord::Migration[7.1]
  tag :predeploy
  disable_ddl_transaction!

  def up
    create_table :rubric_assessment_imports, if_not_exists: true do |t|
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false
      t.string :workflow_state, null: false
      t.references :user, foreign_key: true
      t.references :assignment, foreign_key: true
      t.references :attachment, foreign_key: true
      t.references :course, foreign_key: true
      t.integer :progress, default: 0, null: false
      t.integer :error_count, default: 0, null: false
      t.json :error_data
      t.timestamps
      t.replica_identity_index
    end
    add_reference :rubric_assessments, :rubric_assessment_imports, foreign_key: true, null: true, if_not_exists: true, index: { algorithm: :concurrently, if_not_exists: true }
  end

  def down
    remove_reference :rubric_assessments, :rubric_assessment_imports, if_exists: true, index: { algorithm: :concurrently, if_exists: true }
    drop_table :rubric_assessment_imports, if_exists: true
  end
end
