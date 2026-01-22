# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

class AddSpanishCollationForSortableNameIndex < ActiveRecord::Migration[8.0]
  tag :predeploy
  disable_ddl_transaction!

  def up
    # Add new locale-specific indexes for Spanish
    add_index :users,
              "(sortable_name COLLATE public.\"es-u-kn-true\"), id",
              name: :index_users_on_sortable_name_es,
              algorithm: :concurrently,
              if_not_exists: true
  end

  def down
    remove_index :users,
                 name: :index_users_on_sortable_name_es,
                 algorithm: :concurrently,
                 if_exists: true
  end
end
