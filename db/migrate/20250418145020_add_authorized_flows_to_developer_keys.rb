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

class AddAuthorizedFlowsToDeveloperKeys < ActiveRecord::Migration[7.1]
  tag :predeploy
  disable_ddl_transaction!

  def change
    add_column :developer_keys, :authorized_flows, :string, array: true, default: [], null: false, limit: 255, if_not_exists: true
    reversible do |dir|
      dir.up do
        DataFixup::BackfillAuthorizedFlowsOnDeveloperKey.run
      end
    end
    add_check_constraint :developer_keys, "authorized_flows <@ ARRAY['service_user_client_credentials']::varchar[]", name: "chk_authorized_flows_enum", validate: false, if_not_exists: true
    validate_constraint :developer_keys, "chk_authorized_flows_enum"
  end
end
