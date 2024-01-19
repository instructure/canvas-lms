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

class BetterGuardLogs < ActiveRecord::Migration[7.0]
  tag :postdeploy

  def up
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
                RAISE EXCEPTION 'guard_excessive_updates: % to %.% failed', TG_OP, TG_TABLE_SCHEMA, TG_TABLE_NAME USING DETAIL = 'Would update ' || record_count || ' records but max is ' || max_record_count;
            ELSE
                RAISE WARNING 'guard_excessive_updates: % to %.% was dangerous', TG_OP, TG_TABLE_SCHEMA, TG_TABLE_NAME USING DETAIL = 'Updated ' || record_count || ' records but threshold is ' || max_record_count;
            END IF;
          END IF;
          RETURN NULL;
      END
      $BODY$ LANGUAGE plpgsql;
    SQL
    set_search_path("guard_excessive_updates")
  end

  def down
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
  end
end
