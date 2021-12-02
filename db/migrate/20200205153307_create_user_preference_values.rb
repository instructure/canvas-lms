# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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
class CreateUserPreferenceValues < ActiveRecord::Migration[5.2]
  tag :predeploy

  def up
    create_table :user_preference_values do |t|
      t.integer :user_id, limit: 8, null: false
      t.string :key, null: false
      t.string :sub_key
      t.text :value
    end

    add_foreign_key :user_preference_values, :users
    add_index :user_preference_values, [:user_id, :key, :sub_key], :unique => true, :name => "index_user_preference_values_on_keys"
  end

  def down
    drop_table :user_preference_values
  end
end
