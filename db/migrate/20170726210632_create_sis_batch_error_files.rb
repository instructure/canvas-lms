#
# Copyright (C) 2017 - present Instructure, Inc.
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
class CreateSisBatchErrorFiles < ActiveRecord::Migration[5.0]
  tag :predeploy

  def change
    create_table :sis_batch_error_files do |t|
      t.integer :sis_batch_id, null: false, limit: 8
      t.integer :attachment_id, null: false, limit: 8
    end
    add_foreign_key :sis_batch_error_files, :sis_batches
    add_foreign_key :sis_batch_error_files, :attachments
    add_index :sis_batch_error_files, [:sis_batch_id, :attachment_id], unique: true
  end
end
