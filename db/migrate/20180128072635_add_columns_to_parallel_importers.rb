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
class AddColumnsToParallelImporters < ActiveRecord::Migration[5.0]
  tag :predeploy

  def change
    remove_column :parallel_importers, :type if column_exists?(:parallel_importers, :type)
    add_column :parallel_importers, :importer_type, :string, null: false, limit: 255
    add_column :parallel_importers, :attachment_id, :integer, limit: 8, null: false
    add_column :parallel_importers, :rows_processed, :integer, default: 0, null: false
    add_foreign_key :parallel_importers, :attachments
    add_index :sis_batches, :attachment_id
  end
end
