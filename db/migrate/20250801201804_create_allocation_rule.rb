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
#

class CreateAllocationRule < ActiveRecord::Migration[7.2]
  tag :predeploy

  def change
    create_table :allocation_rules do |t|
      t.references :root_account, null: false, foreign_key: { to_table: :accounts }, index: false
      t.references :course, null: false, foreign_key: true
      t.references :assignment, null: false, foreign_key: true, index: false
      t.references :assessor, null: false, foreign_key: { to_table: :users }
      t.references :assessee, null: false, foreign_key: { to_table: :users }
      t.boolean :must_review, default: true, null: false
      t.boolean :review_permitted, default: true, null: false
      t.boolean :applies_to_assessor, default: true, null: false

      t.string :workflow_state, default: "active", null: false
      t.check_constraint "workflow_state IN ('active', 'deleted')", name: "chk_workflow_state_enum"

      t.timestamps

      t.index %i[assignment_id assessor_id], name: "index_allocation_rules_on_assignment_assessor"
      t.index %i[assignment_id assessee_id], name: "index_allocation_rules_on_assignment_assessee"

      t.replica_identity_index
    end
  end
end
