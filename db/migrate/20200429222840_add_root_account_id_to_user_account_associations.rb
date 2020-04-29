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
class AddRootAccountIdToUserAccountAssociations < ActiveRecord::Migration[5.2]
  include MigrationHelpers::AddColumnAndFk

  tag :predeploy
  disable_ddl_transaction!

  def up
    add_column_and_fk :user_account_associations, :root_account_id, :accounts
    add_index :user_account_associations, :root_account_id, algorithm: :concurrently
  end

  def down
    remove_column :user_account_associations, :root_account_id
  end
end
