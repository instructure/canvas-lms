# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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
class CreateStandardGradeStatuses < ActiveRecord::Migration[7.0]
  tag :predeploy
  def change
    create_table :standard_grade_statuses do |t|
      t.string :color, limit: 7, null: false
      t.string :status_name, null: false
      t.boolean :hidden, default: false, null: false
      t.references :root_account, null: false, foreign_key: { to_table: :accounts }, index: false
      t.timestamps
    end
    add_index :standard_grade_statuses, [:status_name, :root_account_id], unique: true, name: "index_standard_status_on_name_and_root_account_id"
    add_replica_identity "StandardGradeStatus", :root_account_id
  end
end
