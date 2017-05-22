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

class CreateAlerts < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    create_table :alerts do |t|
      t.integer :context_id, :limit => 8
      t.string :context_type
      t.text :recipients
      t.integer :repetition

      t.timestamps null: true
    end

    create_table :alert_criteria do |t|
      t.integer :alert_id, :limit => 8
      t.string :criterion_type
      t.float :threshold
    end
  end

  def self.down
    drop_table :alert_criteria
    drop_table :alerts
  end
end
