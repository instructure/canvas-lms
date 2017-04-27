#
# Copyright (C) 2013 - present Instructure, Inc.
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

class CreateFeatureFlags < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    create_table :feature_flags do |t|
      t.integer :context_id, limit: 8, null: false
      t.string :context_type, null: false
      t.string :feature, null: false
      t.string :state, default: 'allowed', null: false
      t.integer :locking_account_id, limit: 8
      t.timestamps null: true
    end
    add_index :feature_flags, [:context_id, :context_type, :feature], unique: true,
              name: 'index_feature_flags_on_context_and_feature'
  end

  def self.down
    drop_table :feature_flags
  end
end
