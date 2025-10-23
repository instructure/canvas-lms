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

class ChangeOAuthClientConfigsTypeConstraint < ActiveRecord::Migration[7.2]
  tag :predeploy

  def change
    change_table :oauth_client_configs, bulk: true do |t|
      t.remove_check_constraint "type IN ('product', 'client_id', 'lti_advantage', 'service_user_key', 'token', 'user', 'tool', 'session', 'ip')", name: "chk_type_enum"
      t.check_constraint "type IN ('custom', 'product', 'client_id', 'lti_advantage', 'service_user_key', 'token', 'user', 'tool', 'session', 'ip')", name: "chk_type_enum"
    end
  end
end
