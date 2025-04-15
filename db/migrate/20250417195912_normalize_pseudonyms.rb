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

class NormalizePseudonyms < ActiveRecord::Migration[7.1]
  tag :postdeploy
  disable_ddl_transaction!

  INDEX_NAMES = %w[unique_with_login_attribute
                   on_unique_id_and_account_id].freeze

  def up
    DataFixup::NormalizePseudonyms.backfill_unique_id_normalized

    change_column_null :pseudonyms, :unique_id_normalized, false # rubocop:disable Migration/ChangeColumnNull

    DataFixup::NormalizePseudonyms.backfill_auth_type

    add_check_constraint :pseudonyms,
                         "(auth_type IS NULL) = (authentication_provider_id IS NULL)",
                         name: "chk_no_auth_type_without_auth_provider",
                         if_not_exists: true,
                         validate: false
    validate_constraint :pseudonyms, "chk_no_auth_type_without_auth_provider"

    INDEX_NAMES.each do |index_name|
      index_name = "index_pseudonyms_#{index_name}"
      # idempotent; if the _old index exists, it's already renamed
      next if index_name_exists?(:pseudonyms, "#{index_name}_old")

      rename_index :pseudonyms, index_name, "#{index_name}_old"
    end

    # rubocop:disable Migration/Predeploy
    # these unique indexes can't be built until the backfull above is complete,
    # and it's okay that they're in a postdeploy because they won't be used
    # by Pseudonym.by_unique_id until the flag is set below
    add_index :pseudonyms,
              [:unique_id_normalized, :account_id],
              name: "index_pseudonyms_on_unique_id_and_account_id",
              algorithm: :concurrently,
              if_not_exists: true

    # now that we have the simple index built, we can (relatively) efficiently identify
    # duplicates before we build the unique indices
    DataFixup::NormalizePseudonyms.dedup_all

    add_index :pseudonyms,
              %i[unique_id_normalized account_id authentication_provider_id],
              name: "index_pseudonyms_unique_without_login_attribute",
              unique: true,
              where: "workflow_state IN ('active', 'suspended') AND login_attribute IS NULL",
              algorithm: :concurrently,
              if_not_exists: true
    add_index :pseudonyms,
              %i[unique_id_normalized account_id authentication_provider_id login_attribute],
              name: "index_pseudonyms_unique_with_login_attribute",
              unique: true,
              where: "workflow_state IN ('active', 'suspended')",
              algorithm: :concurrently,
              if_not_exists: true
    add_index :pseudonyms,
              %i[unique_id_normalized account_id],
              name: "index_pseudonyms_unique_for_inferred_auth_providers",
              unique: true,
              where: <<~SQL.squish,
                workflow_state IN ('active', 'suspended') AND
                (authentication_provider_id IS NULL OR
                  auth_type IN ('canvas', 'cas', 'ldap', 'saml')
                )
              SQL
              algorithm: :concurrently,
              if_not_exists: true
    # rubocop:enable Migration/Predeploy

    # don't drop the old indexes yet; app servers may still be using them, due to caching of shards
    # and the conditional in Pseudonym.by_unique_id

    s = Shard.current
    s.reload # make sure we have the real deal
    s.settings["pseudonyms_normalized"] = true
    s.save!
  end

  def down
    remove_index :pseudonyms,
                 name: "index_pseudonyms_unique_for_inferred_auth_providers",
                 algorithm: :concurrently,
                 if_exists: true
    INDEX_NAMES.each do |index_name|
      index_name = "index_pseudonyms_#{index_name}"
      next unless index_name_exists?(:pseudonyms, "#{index_name}_old")

      remove_index :pseudonyms,
                   name: index_name,
                   algorithm: :concurrently,
                   if_exists: true
      rename_index :pseudonyms, "#{index_name}_old", index_name
    end
    remove_check_constraint :pseudonyms,
                            name: "chk_no_auth_type_without_auth_provider",
                            if_exists: true
    change_column_null :pseudonyms, :unique_id_normalized, true

    Pseudonym.active.where("unique_id LIKE 'NORMALIZATION-COLLISION-%'").find_each(strategy: :id) do |p|
      p.update!(unique_id: p.unique_id[61..])
    end
  end
end
