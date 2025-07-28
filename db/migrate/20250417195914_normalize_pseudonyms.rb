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
                   unique_without_login_attribute
                   unique_without_auth_provider
                   on_unique_id_and_account_id].freeze

  def up
    # cleanup from a prior version of this migration
    remove_index :pseudonyms,
                 name: "index_pseudonyms_unique_for_inferred_auth_providers",
                 concurrently: true,
                 if_exists: true

    execute("DROP TRIGGER IF EXISTS pseudonyms_before_insert_or_update_infer_auth_type__tr ON #{Pseudonym.quoted_table_name}")
    execute("DROP FUNCTION IF EXISTS #{connection.quote_table_name("pseudonyms_before_insert_or_update_infer_auth_type__tr_fn")}()")
    remove_column :pseudonyms, :auth_type, if_exists: true

    DataFixup::NormalizePseudonyms.backfill_unique_id_normalized

    change_column_null :pseudonyms, :unique_id_normalized, false # rubocop:disable Migration/ChangeColumnNull

    INDEX_NAMES.each do |index_name|
      index_name = "index_pseudonyms_#{index_name}"
      # idempotent; if the _old index exists, it's already renamed
      next if index_name_exists?(:pseudonyms, "#{index_name}_old")

      rename_index :pseudonyms, index_name, "#{index_name}_old"
    end

    # rubocop:disable Migration/Predeploy

    add_index :pseudonyms,
              [:unique_id_normalized, :account_id],
              name: "index_pseudonyms_on_unique_id_and_account_id",
              algorithm: :concurrently,
              if_not_exists: true

    execute(<<~SQL) # rubocop:disable Rails/SquishedSQLHeredocs
      CREATE OR REPLACE FUNCTION #{connection.quote_table_name("pseudonyms_before_insert_or_update_enforce_unique_across_auth_providers__tr_fn")}()
      RETURNS trigger AS $$
      DECLARE
        auth_type TEXT;
      BEGIN
        IF (OLD.authentication_provider_id IS DISTINCT FROM NEW.authentication_provider_id OR
            OLD.unique_id_normalized IS DISTINCT FROM NEW.unique_id_normalized OR
            OLD.account_id IS DISTINCT FROM NEW.account_id OR
            OLD.workflow_state IS DISTINCT FROM NEW.workflow_state) AND
            NEW.workflow_state <> 'deleted' THEN
          IF NEW.authentication_provider_id IS NOT NULL THEN
            SELECT ap.auth_type
            INTO auth_type
            FROM authentication_providers ap
            WHERE ap.id = NEW.authentication_provider_id;
          ELSE
            auth_type := NULL;
          END IF;

          IF auth_type IN ('cas', 'saml', 'canvas', 'ldap') THEN
            IF EXISTS (
              SELECT 1
              FROM pseudonyms p
              WHERE p.unique_id_normalized = NEW.unique_id_normalized
                AND p.account_id = NEW.account_id
                AND p.workflow_state <> 'deleted'
                AND p.authentication_provider_id IS NULL
                AND p.id <> NEW.id
            ) THEN
              RAISE EXCEPTION 'duplicate unique_id_normalized found against unassociated pseudonyms'
              USING ERRCODE = '23505',
              DETAIL = format('Key (unique_id_normalized, account_id)=(%s, %s) already exists.', NEW.unique_id_normalized, NEW.account_id);
            END IF;
          ELSIF auth_type IS NULL THEN
            IF EXISTS (
              SELECT 1
              FROM pseudonyms p
              JOIN authentication_providers ap ON ap.id = p.authentication_provider_id
              WHERE p.unique_id_normalized = NEW.unique_id_normalized
                AND p.account_id = NEW.account_id
                AND p.workflow_state <> 'deleted'
                AND ap.auth_type IN ('cas', 'saml', 'canvas', 'ldap')
                AND p.id <> NEW.id
            ) THEN
              RAISE EXCEPTION 'duplicate unique_id_normalized found for unassociated pseudonym'
              USING ERRCODE = '23505',
              DETAIL = format('Key (unique_id_normalized, account_id)=(%s, %s) already exists.', NEW.unique_id_normalized, NEW.account_id);
            END IF;
          END IF;
        END IF;

        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql SET search_path TO #{Shard.current.name};
    SQL

    execute(<<~SQL.squish)
      CREATE OR REPLACE TRIGGER pseudonyms_before_insert_or_update_enforce_unique_across_auth_providers__tr
        BEFORE INSERT OR UPDATE ON #{Pseudonym.quoted_table_name}
        FOR EACH ROW
        EXECUTE PROCEDURE #{connection.quote_table_name("pseudonyms_before_insert_or_update_enforce_unique_across_auth_providers__tr_fn")}()
    SQL

    # now that we have the simple index built, we can (relatively) efficiently identify
    # duplicates before we build the unique indices
    DataFixup::NormalizePseudonyms.dedup_all

    # at this point we've re-written every row in the table, so let's try and
    # clean things up before doing too much more work
    Pseudonym.vacuum unless connection.transaction_open?

    # this unique index can't be built until the backfill above is complete,
    # and it's okay that they're in a postdeploy because they won't be used
    # by Pseudonym.by_unique_id until the flag is set below

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
              name: "index_pseudonyms_unique_without_auth_provider",
              unique: true,
              where: "workflow_state IN ('active', 'suspended') AND authentication_provider_id IS NULL",
              algorithm: :concurrently,
              if_not_exists: true
    # rubocop:enable Migration/Predeploy

    s = Shard.current
    unless s.is_a?(Switchman::DefaultShard)
      s.reload # make sure we have the real deal
      s.settings["pseudonyms_normalized"] = true
      s.save!
    end

    # don't drop the _old indexes yet; app servers may still be using them, due to caching of shards
    # and the conditional in Pseudonym.by_unique_id
  end

  def down
    s = Shard.current
    unless s.is_a?(Switchman::DefaultShard)
      s.reload # make sure we have the real deal
      s.settings["pseudonyms_normalized"] = false
      s.save!
    end

    execute("DROP TRIGGER IF EXISTS pseudonyms_before_insert_or_update_enforce_unique_across_auth_providers__tr ON #{Pseudonym.quoted_table_name}")
    execute("DROP FUNCTION IF EXISTS #{connection.quote_table_name("pseudonyms_before_insert_or_update_enforce_unique_across_auth_providers__tr_fn")}")

    remove_index :pseudonyms,
                 name: "index_pseudonyms_unique_without_login_attribute",
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
    change_column_null :pseudonyms, :unique_id_normalized, true

    scope = Pseudonym.active.where("LOWER(unique_id) LIKE 'normalization-collision-%'").limit(100)

    loop do
      count = scope.update_all("unique_id = SUBSTR(unique_id, 62), unique_id_normalized = SUBSTR(unique_id_normalized, 62), updated_at = NOW()")
      break if count.zero?
    end
  end
end
