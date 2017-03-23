#
# Copyright (C) 2016 - present Instructure, Inc.
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

class FixUserActiveOnlyGistIndexes < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!
  tag :postdeploy

  def self.up
    if schema = connection.extension_installed?(:pg_trgm)
      remove_index :users, name: 'index_trgm_users_name_active_only' if index_name_exists?(:users, 'index_trgm_users_name_active_only', false)

      add_index :users, "LOWER(name) #{schema}.gist_trgm_ops",
                name: "index_trgm_users_name_active_only",
                using: :gist,
                algorithm: :concurrently,
                where: "workflow_state IN ('registered', 'pre_registered')"
    end
  end

  def self.down
    if schema = connection.extension_installed?(:pg_trgm)
      remove_index :users, name: 'index_trgm_users_name_active_only' if index_name_exists?(:users, 'index_trgm_users_name_active_only', false)

      add_index :users, "LOWER(short_name) #{schema}.gist_trgm_ops",
                name: "index_trgm_users_short_name_active_only",
                using: :gist,
                algorithm: :concurrently,
                where: "workflow_state IN ('registered', 'pre_registered')"
    end
  end
end
