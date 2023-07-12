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
class CreateCustomGradeStatuses < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!
  tag :predeploy
  def change
    create_table :custom_grade_statuses do |t|
      t.string :color, limit: 7, null: false
      t.string :name, null: false, limit: 14
      t.string :workflow_state, null: false, default: "active", limit: 255
      t.references :root_account, null: false, foreign_key: { to_table: :accounts }, index: false
      t.references :created_by, null: false, foreign_key: { to_table: :users }, index: true
      t.references :deleted_by, null: true, foreign_key: { to_table: :users }, index: true
      t.timestamps
    end
    add_replica_identity "CustomGradeStatus", :root_account_id
    add_reference :submissions, :custom_grade_status, foreign_key: true, index: { algorithm: :concurrently, where: "custom_grade_status_id IS NOT NULL" }, if_not_exists: true
    add_reference :scores, :custom_grade_status, foreign_key: true, index: { algorithm: :concurrently, where: "custom_grade_status_id IS NOT NULL" }, if_not_exists: true
  end
end
