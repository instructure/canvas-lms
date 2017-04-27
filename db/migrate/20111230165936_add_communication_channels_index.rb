#
# Copyright (C) 2011 - present Instructure, Inc.
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

class AddCommunicationChannelsIndex < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    if connection.adapter_name == 'PostgreSQL'
      remove_index :communication_channels, [:path, :path_type]
      connection.execute("CREATE INDEX index_communication_channels_on_path_and_path_type ON #{CommunicationChannel.quoted_table_name} (LOWER(path), path_type)")
    end
  end

  def self.down
    if connection.adapter_name == 'PostgreSQL'
      connection.execute("DROP INDEX index_communication_channels_on_path_and_path_type")
      add_index :communication_channels, [:path, :path_type]
    end
  end
end
