# frozen_string_literal: true

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

class DropCollkeyIndexes < ActiveRecord::Migration[7.0]
  tag :postdeploy
  disable_ddl_transaction!

  def recreate_index(table, index_name, column, conditions = nil)
    return if connection.index_name_exists?(table, index_name)

    collkey = connection.extension(:pg_collkey)&.schema

    columns = if collkey
                "#{collkey}.collkey(#{column}, 'root', false, 3, true)"
              else
                "CAST(LOWER(replace(#{column}, '\\', '\\\\')) AS bytea)"
              end
    columns = yield columns if block_given?

    add_index table, columns, name: index_name, where: conditions, algorithm: :concurrently, if_not_exists: true # rubocop:disable Migration/Predeploy
  end

  def up
    remove_index :users, name: :index_users_on_sortable_name_collkey, if_exists: true
    remove_index :attachments, name: :index_attachments_collkey, if_exists: true

    connection.transaction(requires_new: true) do
      drop_extension(:pg_collkey, if_exists: true)
    rescue ActiveRecord::StatementInvalid
      # can't drop; ignore
      raise ActiveRecord::Rollback
    end
  end

  def down
    connection.transaction(requires_new: true) do
      create_extension(:pg_collkey, schema: connection.shard.name, if_not_exists: true)
    rescue ActiveRecord::StatementInvalid
      # can't create; ignore
      raise ActiveRecord::Rollback
    end

    recreate_index(:users, :index_users_on_sortable_name_collkey, :sortable_name) { |columns| "#{columns}, id" }
    recreate_index(:attachments, :index_attachments_collkey, :display_name, "folder_id IS NOT NULL") { |columns| "folder_id, file_state, #{columns}" }
  end
end
