#
# Copyright (C) 2018 - present Instructure, Inc.
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

class CreateToolConfigurations < ActiveRecord::Migration[5.1]
  tag :predeploy

  def change
    create_table :lti_tool_configurations do |t|
      t.references :developer_key, limit: 8, null: false, foreign_key: true, index: false
      t.jsonb :settings, null: false
      t.timestamps null: false
    end

    add_index :lti_tool_configurations, :developer_key_id, unique: true
  end
end
