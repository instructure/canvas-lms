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

class RemoveUniquenessConstraintFromUserMergeDataRecords < ActiveRecord::Migration[5.2]
  tag :predeploy
  disable_ddl_transaction!

  def up
    remove_index :user_merge_data_records, name: "index_user_merge_data_records_on_context_id_and_context_type", if_exists: true
    add_index :user_merge_data_records, [:context_id, :context_type, :user_merge_data_id, :previous_user_id],
      name: "index_user_merge_data_records_on_context_id_and_context_type", algorithm: :concurrently
  end

  def down
    remove_index :user_merge_data_records, name: "index_user_merge_data_records_on_context_id_and_context_type", if_exists: true
    add_index :user_merge_data_records, [:context_id, :context_type, :user_merge_data_id, :previous_user_id],
              unique: true, name: "index_user_merge_data_records_on_context_id_and_context_type", algorithm: :concurrently
  end
end
