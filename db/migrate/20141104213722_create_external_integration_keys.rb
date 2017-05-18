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

class CreateExternalIntegrationKeys < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    create_table :external_integration_keys do |t|
      t.integer :context_id, limit: 8, null: false
      t.string :context_type, null: false
      t.string :key_value, null: false, length: 255
      t.string :key_type, null: false

      t.timestamps null: true
    end

    add_index :external_integration_keys, [:context_id, :context_type, :key_type], name: 'index_external_integration_keys_unique', unique: true
  end
end
