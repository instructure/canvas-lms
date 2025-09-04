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

class CreateAccessibilityIssues < ActiveRecord::Migration[7.2]
  tag :predeploy

  def change
    rule_types = Accessibility::Rule.registry.keys.map { |type| ActiveRecord::Base.connection.quote(type) }.join(", ")
    create_table :accessibility_issues do |t|
      t.references :root_account, null: false, foreign_key: { to_table: :accounts }, index: false
      t.references :course, null: false, foreign_key: true, index: true

      t.references :context, polymorphic: %i[wiki_page assignment attachment], foreign_key: true, check_constraint: false
      t.check_constraint <<~SQL.squish, name: "chk_require_context"
        (wiki_page_id IS NOT NULL AND assignment_id IS NULL AND attachment_id IS NULL) OR
        (wiki_page_id IS NULL AND assignment_id IS NOT NULL AND attachment_id IS NULL) OR
        (wiki_page_id IS NULL AND assignment_id IS NULL AND attachment_id IS NOT NULL)
      SQL

      t.string :rule_type, null: false, index: true
      t.check_constraint "rule_type IN (#{rule_types})", name: "chk_rule_type_enum"

      t.text :node_path, limit: 1024
      t.jsonb :metadata, null: false, default: {}

      t.string :workflow_state, default: "active", null: false
      t.check_constraint "workflow_state IN ('active', 'resolved', 'dismissed')", name: "chk_workflow_state_enum"

      t.references :updated_by, foreign_key: { to_table: :users }, index: { where: "updated_by_id IS NOT NULL" }

      t.timestamps

      t.replica_identity_index
    end
  end
end
