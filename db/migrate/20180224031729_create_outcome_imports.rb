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

class CreateOutcomeImports < ActiveRecord::Migration[5.0]
  tag :predeploy

  def change
    create_table :outcome_imports do |t|
      t.string :workflow_state, null: false
      t.integer :context_id, limit: 8, null: false
      t.string :context_type, null: false
      t.references :user, foreign_key: true, limit: 8
      t.references :attachment, foreign_key: true, limit: 8
      t.integer :progress
      t.timestamp :ended_at

      t.timestamps
    end

    add_index :outcome_imports, %i[context_type context_id]
  end
end
