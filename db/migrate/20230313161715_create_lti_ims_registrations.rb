# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

class CreateLtiIMSRegistrations < ActiveRecord::Migration[7.0]
  tag :predeploy

  def up
    create_table :lti_ims_registrations do |t|
      t.jsonb :lti_tool_configuration, null: false
      t.references :developer_key, null: false, foreign_key: true, index: true
      t.string :application_type, null: false
      t.text :grant_types, array: true, default: [], null: false
      t.text :response_types, array: true, default: [], null: false
      t.text :redirect_uris, array: true, default: [], null: false
      t.text :initiate_login_uri, null: false
      t.string :client_name, null: false
      t.text :jwks_uri, null: false
      t.text :logo_uri
      t.string :token_endpoint_auth_method, null: false
      t.string :contacts, array: true, default: [], null: false, limit: 255
      t.text :client_uri
      t.text :policy_uri
      t.text :tos_uri
      t.text :scopes, array: true, default: [], null: false

      t.references :root_account, foreign_key: { to_table: :accounts }, null: false, index: false
      t.timestamps
    end

    add_replica_identity "Lti::IMS::Registration", :root_account_id, 0
  end

  def down
    drop_table :lti_ims_registrations
  end
end
