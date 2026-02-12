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

class ReplaceIndexOnLtiToolConfigurationsDeveloperKeyId < ActiveRecord::Migration[8.0]
  tag :predeploy
  disable_ddl_transaction!

  def up
    change_column_null :lti_tool_configurations, :developer_key_id, true

    add_index :lti_tool_configurations,
              %i[developer_key_id lti_registration_id],
              name: "index_lti_tool_configs_on_dev_key_id_and_lti_reg_id",
              unique: true,
              algorithm: :concurrently,
              if_not_exists: true

    remove_index :lti_tool_configurations,
                 name: "index_lti_tool_configurations_on_developer_key_id",
                 algorithm: :concurrently,
                 if_exists: true
  end

  def down
    add_index :lti_tool_configurations,
              :developer_key_id,
              name: "index_lti_tool_configurations_on_developer_key_id",
              unique: true,
              algorithm: :concurrently,
              if_not_exists: true

    remove_index :lti_tool_configurations,
                 name: "index_lti_tool_configs_on_dev_key_id_and_lti_reg_id",
                 algorithm: :concurrently,
                 if_exists: true
  end
end
