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

class AddColumnsToToolConfiguration < ActiveRecord::Migration[7.1]
  tag :predeploy

  def change
    change_table :lti_tool_configurations, bulk: true do |t|
      t.string :title, limit: 255
      t.text :description, limit: 4_000
      t.string :target_link_uri, limit: 4_000
      t.string :domain, limit: 4_000
      t.string :tool_id, limit: 255
      t.string :public_jwk_url, limit: 4_000
      t.string :oidc_initiation_url, limit: 4_000
      t.jsonb :oidc_initiation_urls, default: {}, null: false
      t.jsonb :custom_fields, default: {}, null: false
      t.jsonb :launch_settings, default: {}, null: false
      t.jsonb :placements, default: [], null: false
      t.jsonb :public_jwk
      t.text :scopes, array: true, default: [], null: false
      t.text :redirect_uris, array: true, default: [], null: false
    end
  end
end
