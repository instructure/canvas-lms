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

class CreateLtiContextControls < ActiveRecord::Migration[7.1]
  tag :predeploy

  def change
    create_table :lti_context_controls do |t|
      t.boolean :available, null: false, default: true
      t.string :path, null: false, limit: 4096, index: true

      t.references :deployment, foreign_key: { to_table: :context_external_tools }, null: false
      t.references :registration, foreign_key: { to_table: :lti_registrations }, null: false
      t.references :account, foreign_key: true, index: false
      t.references :course, foreign_key: true, index: false

      t.check_constraint <<~SQL.squish, name: "chk_require_context"
        (account_id IS NOT NULL OR
        course_id IS NOT NULL) AND NOT
        (account_id IS NOT NULL AND course_id IS NOT NULL)
      SQL
      t.index [:course_id, :registration_id], unique: true, where: "course_id IS NOT NULL", name: "index_lti_context_controls_on_course_and_registration"
      t.index [:account_id, :registration_id], unique: true, where: "account_id IS NOT NULL", name: "index_lti_context_controls_on_account_and_registration"

      t.references :created_by, foreign_key: { to_table: :users }, index: { where: "created_by_id IS NOT NULL" }
      t.references :updated_by, foreign_key: { to_table: :users }, index: { where: "updated_by_id IS NOT NULL" }
      t.string :workflow_state, limit: 48, null: false, default: "active"
      t.timestamps

      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false
      t.replica_identity_index
    end
  end
end
