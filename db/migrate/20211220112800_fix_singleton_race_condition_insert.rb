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
class FixSingletonRaceConditionInsert < ActiveRecord::Migration[5.2]
  tag :predeploy

  def change
    reversible do |direction|
      direction.up do
        execute(<<~SQL)
          CREATE OR REPLACE FUNCTION #{connection.quote_table_name("delayed_jobs_before_insert_row_tr_fn")} () RETURNS trigger AS $$
          BEGIN
            IF NEW.strand IS NOT NULL THEN
              PERFORM pg_advisory_xact_lock(half_md5_as_bigint(NEW.strand));
              IF (SELECT COUNT(*) FROM (
                  SELECT 1 FROM delayed_jobs WHERE strand = NEW.strand AND next_in_strand=true LIMIT NEW.max_concurrent
                ) s) = NEW.max_concurrent THEN
                NEW.next_in_strand := false;
              END IF;
            END IF;
            IF NEW.singleton IS NOT NULL THEN
              PERFORM pg_advisory_xact_lock(half_md5_as_bigint(CONCAT('singleton:', NEW.singleton)));
              -- this condition seems silly, but it forces postgres to use the two partial indexes on singleton,
              -- rather than doing a seq scan
              PERFORM 1 FROM delayed_jobs WHERE singleton = NEW.singleton AND (locked_by IS NULL OR locked_by IS NOT NULL);
              IF FOUND THEN
                NEW.next_in_strand := false;
              END IF;
            END IF;
            RETURN NEW;
          END;
          $$ LANGUAGE plpgsql SET search_path TO #{::Switchman::Shard.current.name};
        SQL
      end
      direction.down do
        execute(<<~SQL)
          CREATE OR REPLACE FUNCTION #{connection.quote_table_name("delayed_jobs_before_insert_row_tr_fn")} () RETURNS trigger AS $$
          BEGIN
            IF NEW.strand IS NOT NULL THEN
              PERFORM pg_advisory_xact_lock(half_md5_as_bigint(NEW.strand));
              IF (SELECT COUNT(*) FROM (
                  SELECT 1 FROM delayed_jobs WHERE strand = NEW.strand AND next_in_strand=true LIMIT NEW.max_concurrent
                ) s) = NEW.max_concurrent THEN
                NEW.next_in_strand := false;
              END IF;
            END IF;
            IF NEW.singleton IS NOT NULL THEN
              -- this condition seems silly, but it forces postgres to use the two partial indexes on singleton,
              -- rather than doing a seq scan
              PERFORM 1 FROM delayed_jobs WHERE singleton = NEW.singleton AND (locked_by IS NULL OR locked_by IS NOT NULL);
              IF FOUND THEN
                NEW.next_in_strand := false;
              END IF;
            END IF;
            RETURN NEW;
          END;
          $$ LANGUAGE plpgsql SET search_path TO #{::Switchman::Shard.current.name};
        SQL
      end
    end
  end
end
# rubocop:enable Rails/SquishedSQLHeredocs
