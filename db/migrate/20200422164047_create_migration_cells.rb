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
class CreateMigrationCells < ActiveRecord::Migration[5.2]
  tag :predeploy

  def up
    create_table :auditor_migration_cells do |t|
      t.bigint :account_id, null: false
      t.integer :year, null: false
      t.integer :month, null: false
      t.integer :day, null: false
      t.boolean :completed, null: false, default: false
      t.boolean :failed, null: false, default: false
      t.string :auditor_type, null: false
      t.timestamps
    end
    add_index :auditor_migration_cells, :account_id
    add_index :auditor_migration_cells, [:auditor_type, :account_id, :year, :month, :day], name: 'index_auditor_migration_cells_by_primary_access_path', unique: true
    add_foreign_key :auditor_migration_cells, :accounts
  end

  def down
    drop_table :auditor_migration_cells
  end
end
