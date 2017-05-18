#
# Copyright (C) 2012 - present Instructure, Inc.
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

class UpdateSortableNameIndex < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!
  tag :predeploy

  def self.up
    if connection.adapter_name == 'PostgreSQL'
      if connection.select_value("SELECT COUNT(*) FROM pg_proc WHERE proname='collkey'").to_i == 0
        remove_index :users, name: 'index_users_on_sortable_name'
        concurrently = " CONCURRENTLY" if connection.open_transactions == 0
        execute("CREATE INDEX#{concurrently} index_users_on_sortable_name ON #{User.quoted_table_name} (CAST(LOWER(replace(sortable_name, '\\', '\\\\')) AS bytea))")
      end
    end
  end

  def self.down
    if connection.adapter_name == 'PostgreSQL'
      if connection.select_value("SELECT COUNT(*) FROM pg_proc WHERE proname='collkey'").to_i == 0
        remove_index :users, name: 'index_users_on_sortable_name'
        concurrently = " CONCURRENTLY" if connection.open_transactions == 0
        execute("CREATE INDEX#{concurrently} index_users_on_sortable_name ON #{User.quoted_table_name} (CAST(LOWER(sortable_name) AS bytea))")
      end
    end
  end
end
