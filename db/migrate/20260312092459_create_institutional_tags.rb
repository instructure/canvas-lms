# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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
class CreateInstitutionalTags < ActiveRecord::Migration[8.0]
  tag :predeploy

  def change
    create_table :institutional_tags do |t|
      t.string :name, null: false, limit: 255
      t.text :description, null: false
      t.string :sis_source_id, limit: 255
      t.references :category, null: false, foreign_key: { to_table: :institutional_tag_categories }
      t.references :sis_batch, foreign_key: true, index: { where: "sis_batch_id IS NOT NULL" }
      t.string :stuck_sis_fields, limit: 255
      t.string :workflow_state, default: "active", null: false, limit: 255
      t.references :root_account, null: false, foreign_key: { to_table: :accounts }, index: false
      t.timestamps

      t.check_constraint "workflow_state IN ('active', 'deleted')", name: "chk_workflow_state_enum"

      t.replica_identity_index
      t.index "root_account_id, LOWER(name)",
              unique: true,
              where: "workflow_state = 'active'",
              name: "index_inst_tags_on_root_acct_lower_name_active"
      t.index %i[sis_source_id root_account_id],
              unique: true,
              where: "sis_source_id IS NOT NULL",
              name: "index_inst_tags_on_sis_source_id_root_acct"
    end
  end
end
