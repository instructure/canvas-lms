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

class AddReadonlyToCustomGradebookColumn < ActiveRecord::Migration[5.0]
  tag :predeploy
  disable_ddl_transaction!

  def up
    add_column :custom_gradebook_columns, :read_only, :boolean
    change_column_default :custom_gradebook_columns, :read_only, false
    DataFixup::BackfillNulls.run(CustomGradebookColumn, :read_only, default_value: false)
    change_column_null :custom_gradebook_columns, :read_only, false
  end

  def down
    remove_column :custom_gradebook_columns, :read_only
  end
end
