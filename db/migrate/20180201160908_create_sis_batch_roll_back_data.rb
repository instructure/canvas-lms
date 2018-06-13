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

class CreateSisBatchRollBackData < ActiveRecord::Migration[5.0]
  tag :predeploy

  def change
    create_table :sis_batch_roll_back_data do |t|
      t.integer :sis_batch_id, null: false, limit: 8
      t.string :context_type, null: false, limit: 255
      t.integer :context_id, null: false, limit: 8
      t.string :previous_workflow_state, null: false, limit: 255
      t.string :updated_workflow_state, null: false, limit: 255
      t.boolean :batch_mode_delete, null: false, default: false
      t.string :workflow_state, null: false, limit: 255, default: 'active'
      t.timestamps null: false
    end

    add_foreign_key :sis_batch_roll_back_data, :sis_batches
    add_index :sis_batch_roll_back_data, :sis_batch_id
    add_index :sis_batch_roll_back_data, :workflow_state
    add_index :sis_batch_roll_back_data, %i(updated_workflow_state previous_workflow_state),
              name: 'index_sis_batch_roll_back_context_workflow_states'
  end
end
