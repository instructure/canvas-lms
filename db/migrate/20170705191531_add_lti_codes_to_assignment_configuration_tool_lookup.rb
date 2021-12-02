# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

class AddLtiCodesToAssignmentConfigurationToolLookup < ActiveRecord::Migration[5.0]
  tag :predeploy
  def change
    add_column :assignment_configuration_tool_lookups, :tool_product_code, :string
    add_column :assignment_configuration_tool_lookups, :tool_vendor_code, :string
    add_column :assignment_configuration_tool_lookups, :tool_resource_type_code, :string
    change_column_null :assignment_configuration_tool_lookups, :tool_id, true
    add_index :assignment_configuration_tool_lookups, [:tool_product_code, :tool_vendor_code, :tool_resource_type_code], name: 'index_resource_codes_on_assignment_configuration_tool_lookups'
  end
end
