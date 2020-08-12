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

class CreateOutcomeCalculationMethods < ActiveRecord::Migration[5.2]
  tag :predeploy

  def change
    create_table :outcome_calculation_methods do |t|
      t.string :context_type, null: false, limit: 255
      t.integer :context_id, null: false, limit: 8
      t.integer :calculation_int, limit: 2
      t.string :calculation_method, null: false, limit: 255
      t.string :workflow_state, null: false, default: 'active'
      t.references :root_account, index: true, foreign_key: { to_table: :accounts }
      t.timestamps null: false
    end

    add_index :outcome_calculation_methods, [:context_type, :context_id], unique: true, name: 'index_outcome_calculation_methods_on_context'
  end
end
