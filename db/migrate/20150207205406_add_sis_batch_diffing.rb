#
# Copyright (C) 2015 - present Instructure, Inc.
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

class AddSisBatchDiffing < ActiveRecord::Migration[4.2]
  tag :predeploy
  disable_ddl_transaction!

  def up
    add_column :sis_batches, :diffing_data_set_identifier, :string
    add_column :sis_batches, :diffing_remaster, :boolean
    add_column :sis_batches, :generated_diff_id, :integer, :limit => 8
    add_index :sis_batches, [:account_id, :diffing_data_set_identifier, :created_at],
      name: 'index_sis_batches_diffing',
      algorithm: :concurrently
  end

  def down
    remove_column :sis_batches, :generated_diff_id
    remove_column :sis_batches, :diffing_remaster
    remove_column :sis_batches, :diffing_data_set_identifier
  end
end
