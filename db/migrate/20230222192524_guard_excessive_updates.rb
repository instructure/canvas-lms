# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

class GuardExcessiveUpdates < ActiveRecord::Migration[7.0]
  tag :postdeploy
  disable_ddl_transaction!

  def up
    execute(<<~SQL.squish)
      CREATE OR REPLACE FUNCTION #{connection.quote_table_name("setting_as_int")}( IN p_setting TEXT ) RETURNS INT4 as $$
      DECLARE
          v_text text;
          v_int8 int8;
      BEGIN
          v_text := current_setting( p_setting, true );

          IF v_text IS NULL THEN
              RETURN NULL;
          END IF;

          IF NOT v_text ~ '^-?[0-9]{1,10}$' THEN
              RETURN NULL;
          END IF;

          v_int8 := v_text::INT8;
          IF v_int8 > 2147483647 OR v_int8 < -2147483648 THEN
              RETURN NULL;
          END IF;
          RETURN v_int8::int4;
      END;
      $$ language plpgsql;
    SQL

    execute(<<~SQL.squish)
      CREATE OR REPLACE FUNCTION #{connection.quote_table_name("guard_excessive_updates")}() RETURNS TRIGGER AS $BODY$
      DECLARE
          record_count integer;
          max_record_count integer;
      BEGIN
          SELECT count(*) FROM oldtbl INTO record_count;
          max_record_count := COALESCE(setting_as_int('inst.max_update_limit.' || TG_TABLE_NAME), setting_as_int('inst.max_update_limit'), '#{PostgreSQLAdapterExtensions::DEFAULT_MAX_UPDATE_LIMIT}');
          IF record_count > max_record_count THEN
              IF current_setting('inst.max_update_fail', true) IS NOT DISTINCT FROM 'true' THEN
                  RAISE EXCEPTION 'guard_excessive_updates: % to %.% failed. Would update % records but max is %', TG_OP, TG_TABLE_SCHEMA, TG_TABLE_NAME, record_count, max_record_count;
              ELSE
                  RAISE WARNING 'guard_excessive_updates: % to %.% was dangerous. Updated % records but threshold is %', TG_OP, TG_TABLE_SCHEMA, TG_TABLE_NAME, record_count, max_record_count;
              END IF;
          END IF;
          RETURN NULL;
      END
      $BODY$ LANGUAGE plpgsql;
    SQL
    set_search_path("guard_excessive_updates")

    metadata = ActiveRecord::InternalMetadata
    metadata = metadata.new(connection) if $canvas_rails == "7.1"
    metadata[:guard_dangerous_changes_installed] = "true"

    ActiveRecord::Base.connection.tables.grep_v(/^_/).each do |table|
      add_guard_excessive_updates(table)
    end
  end

  def down
    execute("DROP FUNCTION IF EXISTS #{connection.quote_table_name("guard_excessive_updates")}() CASCADE")
    execute("DROP FUNCTION IF EXISTS #{connection.quote_table_name("setting_as_int")}( IN p_setting TEXT ) CASCADE")
    ::ActiveRecord::InternalMetadata[:guard_dangerous_changes_installed] = "false"
  end
end
