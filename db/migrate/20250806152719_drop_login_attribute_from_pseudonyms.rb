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

# rubocop:disable Migration/Predeploy

class DropLoginAttributeFromPseudonyms < ActiveRecord::Migration[7.2]
  tag :postdeploy
  disable_ddl_transaction!

  def up
    # build a temporary index to allow us to clean up now-duplicated pseudonyms more efficiently
    add_index :pseudonyms,
              %i[authentication_provider_id unique_id_normalized],
              where: "workflow_state <> 'deleted' AND login_attribute IS NOT NULL",
              name: "index_temp_pseudonyms_on_login_attribute",
              algorithm: :concurrently,
              if_not_exists: true

    now = Time.now.utc
    # these pseudonyms are for the wrong login attribute, so we need to delete them
    # before we lose this information
    user_ids = []
    Pseudonym.active
             .where.not(login_attribute: nil)
             .joins(:authentication_provider)
             .merge(AuthenticationProvider.active)
             .where("pseudonyms.login_attribute<>authentication_providers.login_attribute")
             .in_batches do |batch|
      user_ids.concat(batch.pluck(:user_id))
      batch.update_all(workflow_state: "deleted", updated_at: now)
    end

    # delete pseudonyms that will soon conflict with a NULL login_attribute
    # (should be nearly impossible, since we set login_attribute on new pseudonyms)
    base_scope = Pseudonym.active
                          .where.not(login_attribute: nil)

    base_scope.where(<<~SQL.squish)
      EXISTS (SELECT 1 FROM #{Pseudonym.quoted_table_name} AS p2
              WHERE p2.authentication_provider_id = pseudonyms.authentication_provider_id
              AND p2.account_id = pseudonyms.account_id
              AND p2.unique_id_normalized = pseudonyms.unique_id_normalized
              AND p2.workflow_state <> 'deleted'
              AND p2.id <> pseudonyms.id)
    SQL
              .pluck(:authentication_provider_id, :unique_id_normalized, :account_id)
              .each do |authentication_provider_id, unique_id_normalized, account_id|
      Pseudonym.active
               .where(authentication_provider_id:, unique_id_normalized:, account_id:)
               .order("login_attribute NULLS LAST")
               .offset(1)
               .in_batches do |batch|
        user_ids.concat(batch.pluck(:user_id))
        batch.update_all(workflow_state: "deleted", updated_at: now)
      end
    end

    remove_index :pseudonyms, name: "index_temp_pseudonyms_on_login_attribute", algorithm: :concurrently # rubocop:disable Migration/NonTransactional

    # need to re-build the "main" unique index, because it currently references the login_attribute
    # attribute column, so will be implicitly dropped with it. See #down for what it replaces
    add_index :pseudonyms,
              %i[unique_id_normalized account_id authentication_provider_id],
              unique: true,
              where: "workflow_state IN ('active', 'suspended')",
              name: "index_pseudonyms_unique",
              algorithm: :concurrently,
              if_not_exists: true

    remove_column :pseudonyms, :login_attribute, if_exists: true # rubocop:disable Rails/BulkChangeTable
    remove_column :pseudonyms, :verification_token, if_exists: true

    User.where(id: user_ids).find_each do |user|
      user.try(:sync_with_identity, root_accounts: nil, sync_type: :delayed)
    end
  end

  def down
    add_column :pseudonyms, :verification_token, :string, limit: 255, if_not_exists: true # rubocop:disable Rails/BulkChangeTable
    add_column :pseudonyms, :login_attribute, :string, limit: 255, if_not_exists: true

    add_check_constraint :pseudonyms, <<~SQL.squish, name: "chk_login_attribute_authentication_provider_id", if_not_exists: true, validate: false
      authentication_provider_id IS NOT NULL OR login_attribute IS NULL
    SQL
    validate_constraint :pseudonyms, "chk_login_attribute_authentication_provider_id"

    add_index :pseudonyms,
              %i[unique_id_normalized account_id authentication_provider_id login_attribute],
              unique: true,
              where: "workflow_state IN ('active', 'suspended')",
              name: "index_pseudonyms_unique_with_login_attribute",
              algorithm: :concurrently,
              if_not_exists: true
    add_index :pseudonyms,
              %i[unique_id_normalized account_id authentication_provider_id],
              unique: true,
              where: "workflow_state IN ('active', 'suspended') AND login_attribute IS NULL",
              name: "index_pseudonyms_unique_without_login_attribute",
              algorithm: :concurrently,
              if_not_exists: true
    remove_index :pseudonyms, name: "index_pseudonyms_unique", if_exists: true, algorithm: :concurrently
  end
end

# rubocop:enable Migration/Predeploy
