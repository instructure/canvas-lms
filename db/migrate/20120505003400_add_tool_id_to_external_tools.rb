#
# Copyright (C) 2012 - present Instructure, Inc.
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

class AddToolIdToExternalTools < ActiveRecord::Migration[4.2]
  tag :predeploy
  def self.up
    # using tool_id instead of developer_key.id lets us
    # use the same keys as www.eduappcenter.com for
    # tying multiple context_external_tools to the
    # same third-party tool
    add_column :context_external_tools, :tool_id, :string
    add_index :context_external_tools, [:tool_id]
    add_column :developer_keys, :tool_id, :string
    add_index :developer_keys, [:tool_id], :unique => true
  end

  def self.down
    remove_column :context_external_tools, :tool_id
    remove_index :context_external_tools, [:tool_id]
    remove_column :developer_keys, :tool_id
    remove_index :developer_keys, [:tool_id]
  end
end
