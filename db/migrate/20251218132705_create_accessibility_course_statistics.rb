# frozen_string_literal: true

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
#

class CreateAccessibilityCourseStatistics < ActiveRecord::Migration[8.0]
  tag :predeploy

  def change
    create_table :accessibility_course_statistics do |t|
      t.references :root_account, null: false, foreign_key: { to_table: :accounts }, index: false
      t.references :course, null: false, foreign_key: true, index: { unique: true }

      t.integer :active_issue_count
      t.string :workflow_state, default: "initialized", null: false
      t.check_constraint "workflow_state IN ('initialized', 'queued', 'in_progress', 'active', 'failed', 'deleted')", name: "chk_workflow_state_enum"

      t.timestamps

      t.replica_identity_index
    end
  end
end
