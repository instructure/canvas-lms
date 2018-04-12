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
#

class CreateAccountReportRunners < ActiveRecord::Migration[5.1]
  tag :predeploy

  def change
    return if table_exists? :account_report_runners
    create_table :account_report_runners do |t|
      t.integer :account_report_id, null: false, limit: 8
      t.string :workflow_state, null: false, default: 'created', limit: 255
      t.string :batch_items, array: true, default: []
      t.timestamps
      t.datetime :started_at
      t.datetime :ended_at
    end
    add_foreign_key :account_report_runners, :account_reports
    add_index :account_report_runners, :account_report_id
  end
end
