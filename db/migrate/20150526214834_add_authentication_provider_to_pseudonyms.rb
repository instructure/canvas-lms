#
# Copyright (C) 2015 - present Instructure, Inc.
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

class AddAuthenticationProviderToPseudonyms < ActiveRecord::Migration[4.2]
  tag :predeploy
  disable_ddl_transaction!

  def up
    add_column :pseudonyms, :authentication_provider_id, :integer, limit: 8
    add_index :pseudonyms, :authentication_provider_id, algorithm: :concurrently, where: "authentication_provider_id IS NOT NULL"
    add_foreign_key :pseudonyms, :account_authorization_configs, column: :authentication_provider_id
    if connection.adapter_name == 'PostgreSQL'
      concurrently = " CONCURRENTLY" if connection.open_transactions == 0
      execute "CREATE UNIQUE INDEX#{concurrently} index_pseudonyms_on_unique_id_and_account_id_and_authentication_provider_id ON #{Pseudonym.quoted_table_name} (LOWER(unique_id), account_id, authentication_provider_id) WHERE workflow_state='active'"
      execute "CREATE UNIQUE INDEX#{concurrently} index_pseudonyms_on_unique_id_and_account_id_no_authentication_provider_id ON #{Pseudonym.quoted_table_name} (LOWER(unique_id), account_id) WHERE workflow_state='active' AND authentication_provider_id IS NULL"
    end
  end

  def down
    remove_column :pseudonyms, :authentication_provider_id
    if connection.adapter_name == 'PostgreSQL'
      remove_index :pseudonyms, name: "index_pseudonyms_on_unique_id_and_account_id_and_authentication_provider_id"
      remove_index :pseudonyms, name: "index_pseudonyms_on_unique_id_and_account_id_and_no_authentication_provider_id"
    end
  end
end
