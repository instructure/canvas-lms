# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

class AddPseudonymLoginAttributes < ActiveRecord::Migration[7.0]
  tag :predeploy
  disable_ddl_transaction!

  def change
    change_table :pseudonyms do |t|
      # the login_attribute the unique_id came from
      t.string :login_attribute, limit: 255, if_not_exists: true
      # a hash of all login attribute names to their value; allows migrating to
      # different login attributes in the future
      t.jsonb :unique_ids, null: false, default: {}, if_not_exists: true

      # login_attribute can only be set if authentication_provider_id is set
      # conversely, if authentication_provider_id IS NULL, login_attribute MUST be NULL
      t.check_constraint <<~SQL.squish, name: "check_login_attribute_authentication_provider_id", validate: false, if_not_exists: true
        authentication_provider_id IS NOT NULL OR login_attribute IS NULL
      SQL
      connection.validate_constraint :pseudonyms, "check_login_attribute_authentication_provider_id"

      t.index "LOWER(unique_id), account_id, authentication_provider_id, login_attribute",
              name: "index_pseudonyms_unique_with_login_attribute",
              unique: true,
              where: "workflow_state IN ('active', 'suspended')",
              algorithm: :concurrently,
              if_not_exists: true
      # this index replaces index_pseudonyms_unique_with_auth_provider
      t.index "LOWER(unique_id), account_id, authentication_provider_id",
              name: "index_pseudonyms_unique_without_login_attribute",
              unique: true,
              where: "workflow_state IN ('active', 'suspended') AND login_attribute IS NULL",
              algorithm: :concurrently,
              if_not_exists: true
      # can't use the reversible form, because Rails can't reliably match indexes with
      # functions on columns, or most where clauses, when using `if_exists`
      reversible do |dir|
        dir.up do
          t.remove_index name: "index_pseudonyms_unique_with_auth_provider",
                         algorithm: :concurrently,
                         if_exists: true
        end
        dir.down do
          t.index "LOWER(unique_id), account_id, authentication_provider_id",
                  name: "index_pseudonyms_unique_with_auth_provider",
                  unique: true,
                  where: "workflow_state IN ('active', 'suspended')",
                  algorithm: :concurrently,
                  if_not_exists: true
        end
      end
    end
  end
end
