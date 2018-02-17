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

class CreateSisBatchErrors < ActiveRecord::Migration[5.0]
  tag :predeploy

  def change
    create_table :sis_batch_errors do |t|
      t.integer :sis_batch_id, limit: 8, null: false
      t.integer :root_account_id, null: false, limit: 8
      t.string :message, null: false, limit: 255
      t.text :backtrace
      t.string :file, limit: 255
      t.boolean :failure, default: false, null: false
      t.integer :row
      t.datetime :created_at, null: false
    end

    add_foreign_key :sis_batch_errors, :sis_batches
    add_foreign_key :sis_batch_errors, :accounts, column: :root_account_id
    add_index :sis_batch_errors, :sis_batch_id
    add_index :sis_batch_errors, :root_account_id
  end
end
