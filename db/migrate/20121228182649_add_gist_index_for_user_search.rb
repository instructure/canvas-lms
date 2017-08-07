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

class AddGistIndexForUserSearch < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!
  tag :predeploy

  def self.up
    if is_postgres?
      connection.transaction(:requires_new => true) do
        begin
          execute("CREATE EXTENSION IF NOT EXISTS pg_trgm SCHEMA #{connection.shard.name}")
        rescue ActiveRecord::StatementInvalid
          raise ActiveRecord::Rollback
        end
      end

      if (schema = connection.extension_installed?(:pg_trgm))
        add_index :users, "lower(name) #{schema}.gist_trgm_ops", name: "index_trgm_users_name", using: :gist, algorithm: :concurrently
        add_index :pseudonyms, "lower(sis_user_id) #{schema}.gist_trgm_ops", name: "index_trgm_pseudonyms_sis_user_id", using: :gist, algorithm: :concurrently
        add_index :communication_channels, "lower(path) #{schema}.gist_trgm_ops", name: "index_trgm_communication_channels_path", using: :gist, algorithm: :concurrently
      end
    end
  end

  def self.down
    if is_postgres?
      execute("DROP INDEX IF EXISTS #{connection.quote_table_name('index_trgm_users_name')}")
      execute("DROP INDEX IF EXISTS #{connection.quote_table_name('index_trgm_pseudonyms_sis_user_id')}")
      execute("DROP INDEX IF EXISTS #{connection.quote_table_name('index_trgm_communication_channels_path')}")
    end
  end
end
