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

class AddUniqueIdNormalizedToPseudonyms < ActiveRecord::Migration[7.1]
  tag :predeploy

  def up
    change_table :pseudonyms, bulk: true do |t|
      t.string :unique_id_normalized, limit: 255
      t.string :auth_type, limit: 255
    end

    execute(<<~SQL) # rubocop:disable Rails/SquishedSQLHeredocs
      CREATE FUNCTION #{connection.quote_table_name("pseudonyms_before_insert_or_update_infer_auth_type__tr_fn")}()
      RETURNS trigger AS $$
      BEGIN
          -- Disallow directly setting auth_type
          IF OLD.auth_type IS DISTINCT FROM NEW.auth_type THEN
            RAISE EXCEPTION 'pseudonyms.auth_type cannot be set directly';
          END IF;

          -- If authentication_provider_id changed, infer the auth_type
          IF OLD.authentication_provider_id IS DISTINCT FROM NEW.authentication_provider_id THEN
            IF NEW.authentication_provider_id IS NOT NULL THEN
              SELECT auth_type INTO NEW.auth_type FROM authentication_providers WHERE id = NEW.authentication_provider_id;
            ELSE
              NEW.auth_type := NULL;
            END IF;
          END IF;
          RETURN NEW;
      END;
      $$ LANGUAGE plpgsql SET search_path TO #{Shard.current.name};
    SQL

    execute(<<~SQL.squish)
      CREATE TRIGGER pseudonyms_before_insert_or_update_infer_auth_type__tr
        BEFORE INSERT OR UPDATE ON #{Pseudonym.quoted_table_name}
        FOR EACH ROW
        EXECUTE PROCEDURE #{connection.quote_table_name("pseudonyms_before_insert_or_update_infer_auth_type__tr_fn")}()
    SQL
  end

  def down
    execute("DROP TRIGGER pseudonyms_before_insert_or_update_infer_auth_type__tr ON #{Pseudonym.quoted_table_name}")
    execute("DROP FUNCTION #{connection.quote_table_name("pseudonyms_before_insert_or_update_infer_auth_type__tr_fn")}")

    change_table :pseudonyms, bulk: true do |t|
      t.remove :auth_type
      t.remove :unique_id_normalized
    end
  end
end
