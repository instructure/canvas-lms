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
class FixSisBatchIdOnGroupCategories < ActiveRecord::Migration[5.0]
  tag :predeploy

  def change
    remove_column :group_categories, :sis_batch_id if column_exists?(:group_categories, :sis_batch_id)
    add_column :group_categories, :sis_batch_id, :integer, limit: 8
    add_foreign_key :group_categories, :sis_batches
    add_index :group_categories, :sis_batch_id
    add_foreign_key :group_categories, :accounts, column: :root_account_id
    add_index :group_categories, :root_account_id
  end
end
