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

class CreateLtiOverlays < ActiveRecord::Migration[7.1]
  tag :predeploy

  def change
    create_table :lti_overlays do |t|
      t.belongs_to :registration, null: false
      t.belongs_to :account, null: false, index: false, foreign_key: true
      t.belongs_to :updated_by, null: false, foreign_key: { to_table: :users }
      t.string :workflow_state, null: false, default: "active", limit: 255
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false

      t.jsonb :data, null: false, default: {}

      t.replica_identity_index
      t.timestamps

      t.index %i[account_id registration_id], unique: true
    end
  end
end
