#
# Copyright (C) 2014 - present Instructure, Inc.
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

class AddIntegrationTypeToContextExternalTools < ActiveRecord::Migration[4.2]
  tag :predeploy
  disable_ddl_transaction!

  def self.up
    add_column :context_external_tools, :integration_type, :string
    add_index :context_external_tools, [:context_id, :context_type, :integration_type], :name => "external_tools_integration_type", :algorithm => :concurrently
  end

  def self.down
    remove_column :context_external_tools, :integration_type
    remove_index :context_external_tools, :name => "external_tools_integration_type"
  end
end
