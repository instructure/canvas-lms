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

class CreateScheduledSmartAlerts < ActiveRecord::Migration[5.2]
  tag :predeploy

  def change
    create_table :scheduled_smart_alerts do |t|
      t.string :context_type, null: false
      t.string :alert_type, null: false
      t.integer :context_id
      t.datetime :due_at
      t.references :root_account, index: true, foreign_key: { to_table: :accounts }
      t.timestamps
    end
    add_index :scheduled_smart_alerts, :due_at
    add_index :scheduled_smart_alerts, [:context_type, :context_id, :alert_type, :root_account_id], :name => 'index_unique_scheduled_smart_alert'
  end
end
