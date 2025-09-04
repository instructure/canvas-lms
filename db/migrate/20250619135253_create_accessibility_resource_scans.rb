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

class CreateAccessibilityResourceScans < ActiveRecord::Migration[7.2]
  tag :predeploy

  def change
    create_table :accessibility_resource_scans do |t|
      t.references :root_account, null: false, foreign_key: { to_table: :accounts }, index: false
      t.references :course, null: false, foreign_key: true, index: true

      t.references :context, polymorphic: %i[wiki_page assignment attachment], foreign_key: true, check_constraint: false
      t.check_constraint <<~SQL.squish, name: "chk_require_context"
        (wiki_page_id IS NOT NULL AND assignment_id IS NULL AND attachment_id IS NULL) OR
        (wiki_page_id IS NULL AND assignment_id IS NOT NULL AND attachment_id IS NULL) OR
        (wiki_page_id IS NULL AND assignment_id IS NULL AND attachment_id IS NOT NULL)
      SQL

      t.string :error_message, limit: 255

      t.string :workflow_state, default: "queued", null: false
      t.check_constraint "workflow_state IN ('queued', 'in_progress', 'completed', 'failed')", name: "chk_workflow_state_enum"

      t.timestamps

      t.replica_identity_index
    end
  end
end
