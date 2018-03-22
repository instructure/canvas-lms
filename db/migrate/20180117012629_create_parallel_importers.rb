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

class CreateParallelImporters < ActiveRecord::Migration[5.0]
  tag :predeploy

  def change
    drop_table :parallel_importers if ActiveRecord::Base.connection.table_exists? 'parallel_importers'
    create_table :parallel_importers do |t|
      t.integer :sis_batch_id, null: false, limit: 8
      t.string :workflow_state, null: false, limit: 255
      t.integer :index, null: false, limit: 8
      t.integer :batch_size, null: false, limit: 8
      t.timestamps null: false
      t.datetime :started_at
      t.datetime :ended_at
    end
    add_foreign_key :parallel_importers, :sis_batches
    add_index :parallel_importers, :sis_batch_id
  end
end
