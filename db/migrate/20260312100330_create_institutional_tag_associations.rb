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
class CreateInstitutionalTagAssociations < ActiveRecord::Migration[8.0]
  tag :predeploy

  def change
    create_table :institutional_tag_associations do |t|
      t.references :institutional_tag, null: false, foreign_key: true
      t.references :context,
                   polymorphic: %i[user course],
                   null: false,
                   foreign_key: true,
                   check_constraint: { name: "chk_require_context" }
      t.references :root_account, null: false, foreign_key: { to_table: :accounts }, index: false
      t.string :sis_source_id, limit: 255
      t.references :sis_batch, foreign_key: true, index: { where: "sis_batch_id IS NOT NULL" }
      t.string :stuck_sis_fields, limit: 255
      t.string :workflow_state, null: false, default: "active", limit: 255

      t.timestamps

      t.check_constraint "workflow_state IN ('active', 'deleted')", name: "chk_workflow_state_enum"

      t.replica_identity_index
      t.index %i[user_id institutional_tag_id],
              unique: true,
              where: "user_id IS NOT NULL AND workflow_state <> 'deleted'",
              name: "index_inst_tag_assoc_unique_user_tag"
      t.index %i[course_id institutional_tag_id],
              unique: true,
              where: "course_id IS NOT NULL AND workflow_state <> 'deleted'",
              name: "index_inst_tag_assoc_unique_course_tag"
      t.index %i[institutional_tag_id user_id],
              where: "user_id IS NOT NULL",
              name: "index_inst_tag_assoc_on_tag_id_user_id"
      t.index %i[institutional_tag_id course_id],
              where: "course_id IS NOT NULL",
              name: "index_inst_tag_assoc_on_tag_id_course_id"
      t.index %i[sis_source_id root_account_id],
              unique: true,
              where: "sis_source_id IS NOT NULL",
              name: "index_inst_tag_assoc_on_sis_source_id_root_acct"
    end
  end
end
