# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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
class DropOldPseudonymUniqueIndexes < ActiveRecord::Migration[7.2]
  tag :postdeploy
  disable_ddl_transaction!

  def up
    remove_index :pseudonyms,
                 name: "index_pseudonyms_unique_with_login_attribute_old",
                 if_exists: true,
                 algorithm: :concurrently
    remove_index :pseudonyms,
                 name: "index_pseudonyms_unique_without_login_attribute_old",
                 if_exists: true,
                 algorithm: :concurrently
    remove_index :pseudonyms,
                 name: "index_pseudonyms_unique_without_auth_provider_old",
                 if_exists: true,
                 algorithm: :concurrently
  end

  def down
    add_index :pseudonyms,
              "LOWER(unique_id), account_id, authentication_provider_id, login_attribute",
              where: "workflow_state IN ('active', 'suspended')",
              name: "index_pseudonyms_unique_with_login_attribute_old",
              unique: true,
              if_not_exists: true,
              algorithm: :concurrently
    add_index :pseudonyms,
              "LOWER(unique_id), account_id, authentication_provider_id",
              where: "workflow_state IN ('active', 'suspended') AND login_attribute IS NULL",
              name: "index_pseudonyms_unique_without_login_attribute_old",
              unique: true,
              if_not_exists: true,
              algorithm: :concurrently
    add_index :pseudonyms,
              "LOWER(unique_id), account_id",
              where: "workflow_state IN ('active', 'suspended') AND authentication_provider_id IS NULL",
              name: "index_pseudonyms_unique_without_auth_provider_old",
              unique: true,
              if_not_exists: true,
              algorithm: :concurrently
  end
end
