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

class CreateAccountReportRows < ActiveRecord::Migration[5.1]
  tag :predeploy

  def change
    return if table_exists? :account_report_rows
    create_table :account_report_rows do |t|
      t.integer :account_report_id, null: false, limit: 8
      t.integer :account_report_runner_id, null: false, limit: 8
      t.integer :row_number
      t.string :row, array: true, default: []
      t.datetime :created_at, null: false
    end
    add_foreign_key :account_report_rows, :account_reports
    add_foreign_key :account_report_rows, :account_report_runners
    add_index :account_report_rows, :account_report_id
    add_index :account_report_rows, :account_report_runner_id
  end
end
