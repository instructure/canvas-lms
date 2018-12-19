#
# Copyright (C) 2018 - present Instructure, Inc.
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

class SpeedUpMaxConcurrentTriggers < ActiveRecord::Migration[5.1]
  tag :predeploy

  def connection
    Delayed::Backend::ActiveRecord::Job.connection
  end

  def up
    if connection.adapter_name == 'PostgreSQL'
      search_path = Shard.current.name
      execute(<<-CODE)
      CREATE OR REPLACE FUNCTION #{connection.quote_table_name('delayed_jobs_after_delete_row_tr_fn')} () RETURNS trigger AS $$
      DECLARE
        running_count integer;
      BEGIN
        IF OLD.strand IS NOT NULL THEN
          PERFORM pg_advisory_xact_lock(half_md5_as_bigint(OLD.strand));
          IF OLD.id % 20 = 0 THEN
            running_count := (SELECT COUNT(*) FROM (
              SELECT 1 as one FROM delayed_jobs WHERE strand = OLD.strand AND next_in_strand = 't' LIMIT OLD.max_concurrent
            ) subquery_for_count);
            IF running_count < OLD.max_concurrent THEN
              UPDATE delayed_jobs SET next_in_strand = 't' WHERE id IN (
                SELECT id FROM delayed_jobs j2 WHERE next_in_strand = 'f' AND
                j2.strand = OLD.strand ORDER BY j2.id ASC LIMIT (OLD.max_concurrent - running_count) FOR UPDATE
              );
            END IF;
          ELSE
            UPDATE delayed_jobs SET next_in_strand = 't' WHERE id =
              (SELECT id FROM delayed_jobs j2 WHERE next_in_strand = 'f' AND
                j2.strand = OLD.strand ORDER BY j2.id ASC LIMIT 1 FOR UPDATE);
          END IF;
        END IF;
        RETURN OLD;
      END;
      $$ LANGUAGE plpgsql SET search_path TO #{search_path};
      CODE

      # don't need the full count on insert
      execute(<<-CODE)
      CREATE OR REPLACE FUNCTION #{connection.quote_table_name('delayed_jobs_before_insert_row_tr_fn')} () RETURNS trigger AS $$
      BEGIN
        IF NEW.strand IS NOT NULL THEN
          PERFORM pg_advisory_xact_lock(half_md5_as_bigint(NEW.strand));
          IF (SELECT COUNT(*) FROM (
              SELECT 1 AS one FROM delayed_jobs WHERE strand = NEW.strand LIMIT NEW.max_concurrent
            ) subquery_for_count) = NEW.max_concurrent THEN
            NEW.next_in_strand := 'f';
          END IF;
        END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql SET search_path TO #{search_path};;
      CODE
    end
  end

  def down
    if connection.adapter_name == 'PostgreSQL'
      search_path = Shard.current.name
      execute(<<-CODE)
      CREATE OR REPLACE FUNCTION #{connection.quote_table_name('delayed_jobs_after_delete_row_tr_fn')} () RETURNS trigger AS $$
      DECLARE
        running_count integer;
      BEGIN
        IF OLD.strand IS NOT NULL THEN
          PERFORM pg_advisory_xact_lock(half_md5_as_bigint(OLD.strand));
          running_count := (SELECT COUNT(*) FROM delayed_jobs WHERE strand = OLD.strand AND next_in_strand = 't');
          IF running_count < OLD.max_concurrent THEN
            UPDATE delayed_jobs SET next_in_strand = 't' WHERE id IN (
              SELECT id FROM delayed_jobs j2 WHERE next_in_strand = 'f' AND
              j2.strand = OLD.strand ORDER BY j2.id ASC LIMIT (OLD.max_concurrent - running_count) FOR UPDATE
            );
          END IF;
        END IF;
        RETURN OLD;
      END;
      $$ LANGUAGE plpgsql SET search_path TO #{search_path};
      CODE

      # don't need the full count on insert
      execute(<<-CODE)
      CREATE OR REPLACE FUNCTION #{connection.quote_table_name('delayed_jobs_before_insert_row_tr_fn')} () RETURNS trigger AS $$
      BEGIN
        IF NEW.strand IS NOT NULL THEN
          PERFORM pg_advisory_xact_lock(half_md5_as_bigint(NEW.strand));
          IF (SELECT COUNT(*) FROM delayed_jobs WHERE strand = NEW.strand) >= NEW.max_concurrent THEN
            NEW.next_in_strand := 'f';
          END IF;
        END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql SET search_path TO #{search_path};;
      CODE
    end
  end
end
