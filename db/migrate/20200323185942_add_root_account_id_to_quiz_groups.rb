#
# Copyright (C) 2020 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify
# the terms of the GNU Affero General Public License as publishe
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but
# WARRANTY; without even the implied warranty of MERCHANTABILITY
# A PARTICULAR PURPOSE. See the GNU Affero General Public Licens
# details.
#
# You should have received a copy of the GNU Affero General Publ
# with this program. If not, see <http://www.gnu.org/licenses/>.

class AddRootAccountIdToQuizGroups < ActiveRecord::Migration[5.2]
  tag :predeploy
  disable_ddl_transaction!
  include MigrationHelpers::AddColumnAndFk

  def up
    add_column_and_fk :quiz_groups, :root_account_id, :accounts
    add_index :quiz_groups, :root_account_id, algorithm: :concurrently
  end

  def down
    remove_column :quiz_groups, :root_account_id
  end
end
