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

class CreateNavMenuLinks < ActiveRecord::Migration[8.0]
  tag :predeploy

  def change
    create_table :nav_menu_links do |t|
      t.references :context, polymorphic: %i[account course], foreign_key: true, null: false, index: false
      t.string :label, null: false, limit: 255
      t.string :url, null: false, limit: 2048

      t.string :nav_type, null: false
      t.check_constraint "nav_type IN ('course', 'account', 'user')", name: "chk_nav_type_enum"
      t.check_constraint "(nav_type = 'course') = (course_id IS NOT NULL)", name: "chk_nav_type_matches_context"

      t.string :workflow_state, default: "active", null: false, limit: 255
      t.check_constraint "workflow_state IN ('active', 'deleted')", name: "chk_workflow_state_enum"
      t.timestamps

      t.index %i[account_id nav_type workflow_state], where: "account_id IS NOT NULL"
      t.index %i[course_id nav_type workflow_state], where: "course_id IS NOT NULL"

      t.references :root_account, null: false, foreign_key: { to_table: :accounts }, index: false

      t.replica_identity_index
    end
  end
end
