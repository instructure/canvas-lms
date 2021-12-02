# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

class UpdatePseudonymUniqueIndexes < ActiveRecord::Migration[6.0]
  tag :predeploy
  disable_ddl_transaction!

  def up
    add_index :pseudonyms,
              "LOWER(unique_id), account_id, authentication_provider_id",
              name: "index_pseudonyms_unique_with_auth_provider",
              if_not_exists: true,
              algorithm: :concurrently,
              unique: true,
              where: "workflow_state IN ('active', 'suspended')"

    add_index :pseudonyms,
              "LOWER(unique_id), account_id",
              name: "index_pseudonyms_unique_without_auth_provider",
              if_not_exists: true,
              algorithm: :concurrently,
              unique: true,
              where: "workflow_state IN ('active', 'suspended') AND authentication_provider_id IS NULL"

    remove_index :pseudonyms,
                 name: "index_pseudonyms_on_unique_id_and_account_id_and_authentication_provider_id",
                 algorithm: :concurrently,
                 if_exists: true
    remove_index :pseudonyms,
                 name: "index_pseudonyms_on_unique_id_and_account_id_no_authentication_provider_id",
                 algorithm: :concurrently,
                 if_exists: true
  end

  def down
    execute "CREATE UNIQUE INDEX index_pseudonyms_on_unique_id_and_account_id_and_authentication_provider_id ON #{Pseudonym.quoted_table_name} (LOWER(unique_id), account_id, authentication_provider_id) WHERE workflow_state='active'"
    execute "CREATE UNIQUE INDEX index_pseudonyms_on_unique_id_and_account_id_no_authentication_provider_id ON #{Pseudonym.quoted_table_name} (LOWER(unique_id), account_id) WHERE workflow_state='active' AND authentication_provider_id IS NULL"

    remove_index :pseudonyms,
                 name: "index_pseudonyms_unique_with_auth_provider",
                 algorithm: :concurrently,
                 if_exists: true
    remove_index :pseudonyms,
                 name: "index_pseudonyms_unique_without_auth_provider",
                 algorithm: :concurrently,
                 if_exists: true
  end
end
