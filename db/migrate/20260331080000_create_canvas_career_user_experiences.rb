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
class CreateCanvasCareerUserExperiences < ActiveRecord::Migration[8.0]
  tag :predeploy

  def change
    create_table :canvas_career_user_experiences do |t|
      t.references :user, null: false, foreign_key: true
      t.references :root_account, null: false, foreign_key: { to_table: :accounts }, index: false
      t.string :workflow_state, default: "active", null: false, limit: 255
      t.timestamps

      t.check_constraint "workflow_state IN ('active', 'deleted')", name: "chk_workflow_state_enum"

      t.index %i[user_id root_account_id],
              unique: true,
              where: "workflow_state = 'active'",
              name: "index_career_user_exp_on_user_root_account_active"

      t.replica_identity_index
    end
  end
end
