#
# Copyright (C) 2014 - present Instructure, Inc.
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

class ReplaceUserSearchIndexesWithGin < ActiveRecord::Migration[5.1]
  tag :postdeploy
  disable_ddl_transaction!

  def up
    if (schema = connection.extension_installed?(:pg_trgm))
      add_index :users, "lower(name) #{schema}.gin_trgm_ops", name: "index_gin_trgm_users_name", using: :gin, algorithm: :concurrently
      add_index :pseudonyms, "lower(sis_user_id) #{schema}.gin_trgm_ops", name: "index_gin_trgm_pseudonyms_sis_user_id", using: :gin, algorithm: :concurrently
      add_index :communication_channels, "lower(path) #{schema}.gin_trgm_ops", name: "index_gin_trgm_communication_channels_path", using: :gin, algorithm: :concurrently
      add_index :pseudonyms, "lower(unique_id) #{schema}.gin_trgm_ops", name: "index_gin_trgm_pseudonyms_unique_id", using: :gin, algorithm: :concurrently

      remove_index :users, name: "index_trgm_users_name"
      remove_index :pseudonyms, name: "index_trgm_pseudonyms_sis_user_id"
      remove_index :communication_channels, name: "index_trgm_communication_channels_path"
      remove_index :pseudonyms, name: "index_trgm_pseudonyms_unique_id"
    end
  end

  def down
    if (schema = connection.extension_installed?(:pg_trgm))
      add_index :users, "lower(name) #{schema}.gist_trgm_ops", name: "index_trgm_users_name", using: :gist, algorithm: :concurrently
      add_index :pseudonyms, "lower(sis_user_id) #{schema}.gist_trgm_ops", name: "index_trgm_pseudonyms_sis_user_id", using: :gist, algorithm: :concurrently
      add_index :communication_channels, "lower(path) #{schema}.gist_trgm_ops", name: "index_trgm_communication_channels_path", using: :gist, algorithm: :concurrently
      add_index :pseudonyms, "lower(unique_id) #{schema}.gist_trgm_ops", name: "index_trgm_pseudonyms_unique_id", using: :gist, algorithm: :concurrently

      remove_index :users, name: "index_gin_trgm_users_name"
      remove_index :pseudonyms, name: "index_gin_trgm_pseudonyms_sis_user_id"
      remove_index :communication_channels, name: "index_gin_trgm_communication_channels_path"
      remove_index :pseudonyms, name: "index_gin_trgm_pseudonyms_unique_id"
    end
  end
end
