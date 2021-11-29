# frozen_string_literal: true

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

# rubocop:disable Rails/SquishedSQLHeredocs
class UpdateConflictingSingletonFunctionToUseIndex < ActiveRecord::Migration[5.2]
  tag :predeploy

  def up
    execute(<<~SQL)
      CREATE OR REPLACE FUNCTION #{connection.quote_table_name("delayed_jobs_before_unlock_delete_conflicting_singletons_row_fn")} () RETURNS trigger AS $$
      BEGIN
        DELETE FROM delayed_jobs WHERE id<>OLD.id AND singleton=OLD.singleton AND locked_by IS NULL;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql SET search_path TO #{::Switchman::Shard.current.name};
    SQL
  end

  def down
    execute(<<~SQL)
      CREATE OR REPLACE FUNCTION #{connection.quote_table_name("delayed_jobs_before_unlock_delete_conflicting_singletons_row_fn")} () RETURNS trigger AS $$
      BEGIN
        IF EXISTS (SELECT 1 FROM delayed_jobs j2 WHERE j2.singleton=OLD.singleton) THEN
          DELETE FROM delayed_jobs WHERE id<>OLD.id AND singleton=OLD.singleton;
        END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql SET search_path TO #{::Switchman::Shard.current.name};
    SQL
  end
end
# rubocop:enable Rails/SquishedSQLHeredocs
