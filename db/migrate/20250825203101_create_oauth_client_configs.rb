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

class CreateOAuthClientConfigs < ActiveRecord::Migration[7.2]
  tag :predeploy

  def change
    create_table :oauth_client_configs do |t|
      t.string :type, null: false
      t.check_constraint "type IN ('product', 'client_id', 'lti_advantage', 'service_user_key', 'token', 'user', 'tool', 'session', 'ip')", name: "chk_type_enum"
      t.string :identifier, null: false, limit: 255
      t.string :client_name, limit: 255
      t.string :comment, limit: 1024

      t.references :root_account, null: false, foreign_key: { to_table: :accounts }, index: false
      t.index %i[type identifier], name: "index_on_client_identifier"
      t.index %i[root_account_id type identifier], unique: true, name: "index_on_root_account_client_identifier"

      t.integer :throttle_maximum
      t.integer :throttle_high_water_mark
      t.integer :throttle_outflow
      t.integer :throttle_upfront_cost

      t.references :updated_by, null: false, foreign_key: { to_table: :users }
      t.string :workflow_state, default: "active", null: false
      t.check_constraint "workflow_state IN ('active', 'deleted')", name: "chk_workflow_state_enum"

      t.timestamps
      t.replica_identity_index
    end
  end
end
