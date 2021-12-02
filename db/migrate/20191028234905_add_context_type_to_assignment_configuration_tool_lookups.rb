# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

class AddContextTypeToAssignmentConfigurationToolLookups < ActiveRecord::Migration[5.2]
  tag :predeploy
  disable_ddl_transaction!

  def up
    add_column :assignment_configuration_tool_lookups, :context_type, :string
    change_column_default(:assignment_configuration_tool_lookups, :context_type, 'Account')
    DataFixup::BackfillNulls.run(AssignmentConfigurationToolLookup, :context_type, default_value: 'Account')
    change_column_null(:assignment_configuration_tool_lookups, :context_type, false)
  end

  def down
    remove_column :assignment_configuration_tool_lookups, :context_type
  end
end
