# frozen_string_literal: true

#
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
#

# rubocop:disable Rails/SquishedSQLHeredocs
class UpdateDeleteTriggerForSingletonUniqueConstraintChange < ActiveRecord::Migration[5.2]
  tag :predeploy

  def up
    execute(<<~SQL)
      CREATE OR REPLACE FUNCTION #{connection.quote_table_name("delayed_jobs_after_delete_row_tr_fn")} () RETURNS trigger AS $$
      DECLARE
        next_strand varchar;
        running_count integer;
        should_lock boolean;
        should_be_precise boolean;
        update_query varchar;
        skip_locked varchar;
        transition boolean;
      BEGIN
        IF OLD.strand IS NOT NULL THEN
          should_lock := true;
          should_be_precise := OLD.id % (OLD.max_concurrent * 4) = 0;

          IF NOT should_be_precise AND OLD.max_concurrent > 16 THEN
            running_count := (SELECT COUNT(*) FROM (
              SELECT 1 as one FROM delayed_jobs WHERE strand = OLD.strand AND next_in_strand = 't' LIMIT OLD.max_concurrent
            ) subquery_for_count);
            should_lock := running_count < OLD.max_concurrent;
          END IF;

          IF should_lock THEN
            PERFORM pg_advisory_xact_lock(half_md5_as_bigint(OLD.strand));
          END IF;

          -- note that we don't really care if the row we're deleting has a singleton, or if it even
          -- matches the row(s) we're going to update. we just need to make sure that whatever
          -- singleton we grab isn't already running (which is a simple existence check, since
          -- the unique indexes ensure there is at most one singleton running, and one queued)
          update_query := 'UPDATE delayed_jobs SET next_in_strand=true WHERE id IN (
            SELECT id FROM delayed_jobs j2
              WHERE next_in_strand=false AND
                j2.strand=$1.strand AND
                (j2.singleton IS NULL OR NOT EXISTS (SELECT 1 FROM delayed_jobs j3 WHERE j3.singleton=j2.singleton AND j3.id<>j2.id AND (j3.locked_by IS NULL OR j3.locked_by = ''#{::Delayed::Backend::Base::ON_HOLD_LOCKED_BY}'' OR j3.locked_by <> ''#{::Delayed::Backend::Base::ON_HOLD_LOCKED_BY}'')))
              ORDER BY j2.strand_order_override ASC, j2.id ASC
              LIMIT ';

          IF should_be_precise THEN
            running_count := (SELECT COUNT(*) FROM (
              SELECT 1 FROM delayed_jobs WHERE strand = OLD.strand AND next_in_strand = 't' LIMIT OLD.max_concurrent
            ) s);
            IF running_count < OLD.max_concurrent THEN
              update_query := update_query || '($1.max_concurrent - $2)';
            ELSE
              -- we have too many running already; just bail
              RETURN OLD;
            END IF;
          ELSE
            update_query := update_query || '1';

            -- n-strands don't require precise ordering; we can make this query more performant
            IF OLD.max_concurrent > 1 THEN
              skip_locked := ' SKIP LOCKED';
            END IF;
          END IF;

          update_query := update_query || ' FOR UPDATE' || COALESCE(skip_locked, '') || ')';
          EXECUTE update_query USING OLD, running_count;
        END IF;

        IF OLD.singleton IS NOT NULL THEN
          PERFORM pg_advisory_xact_lock(half_md5_as_bigint(CONCAT('singleton:', OLD.singleton)));

          transition := EXISTS (SELECT 1 FROM delayed_jobs AS j1 WHERE j1.singleton = OLD.singleton AND j1.strand IS DISTINCT FROM OLD.strand AND locked_by IS NULL);

          IF transition THEN
            next_strand := (SELECT j1.strand FROM delayed_jobs AS j1 WHERE j1.singleton = OLD.singleton AND j1.strand IS DISTINCT FROM OLD.strand AND locked_by IS NULL AND j1.strand IS NOT NULL LIMIT 1);

            IF next_strand IS NOT NULL THEN
              -- if the singleton has a new strand defined, we need to lock it to ensure we obey n_strand constraints --
              IF NOT pg_try_advisory_xact_lock(half_md5_as_bigint(next_strand)) THEN
                -- a failure to acquire the lock means that another process already has it and will thus handle this singleton --
                RETURN OLD;
              END IF;
            END IF;
          ELSIF OLD.strand IS NOT NULL THEN
            -- if there is no transition and there is a strand then we have already handled this singleton in the case above --
            RETURN OLD;
          END IF;

          -- handles transitioning a singleton from stranded to not stranded --
          -- handles transitioning a singleton from unstranded to stranded --
          -- handles transitioning a singleton from strand A to strand B --
          -- these transitions are a relatively rare case, so we take a shortcut and --
          -- only start the next singleton if its strand does not currently have any running jobs --
          -- if it does, the next stranded job that finishes will start this singleton if it can --
          UPDATE delayed_jobs SET next_in_strand=true WHERE id IN (
            SELECT id FROM delayed_jobs j2
              WHERE next_in_strand=false AND
                j2.singleton=OLD.singleton AND
                j2.locked_by IS NULL AND
                (j2.strand IS NULL OR NOT EXISTS (SELECT 1 FROM delayed_jobs j3 WHERE j3.strand=j2.strand AND j3.id<>j2.id))
              FOR UPDATE
            );
        END IF;
        RETURN OLD;
      END;
      $$ LANGUAGE plpgsql SET search_path TO #{::Switchman::Shard.current.name};
    SQL
  end

  def down
    execute(<<~SQL)
      CREATE OR REPLACE FUNCTION #{connection.quote_table_name("delayed_jobs_after_delete_row_tr_fn")} () RETURNS trigger AS $$
      DECLARE
        next_strand varchar;
        running_count integer;
        should_lock boolean;
        should_be_precise boolean;
        update_query varchar;
        skip_locked varchar;
        transition boolean;
      BEGIN
        IF OLD.strand IS NOT NULL THEN
          should_lock := true;
          should_be_precise := OLD.id % (OLD.max_concurrent * 4) = 0;

          IF NOT should_be_precise AND OLD.max_concurrent > 16 THEN
            running_count := (SELECT COUNT(*) FROM (
              SELECT 1 as one FROM delayed_jobs WHERE strand = OLD.strand AND next_in_strand = 't' LIMIT OLD.max_concurrent
            ) subquery_for_count);
            should_lock := running_count < OLD.max_concurrent;
          END IF;

          IF should_lock THEN
            PERFORM pg_advisory_xact_lock(half_md5_as_bigint(OLD.strand));
          END IF;

          -- note that we don't really care if the row we're deleting has a singleton, or if it even
          -- matches the row(s) we're going to update. we just need to make sure that whatever
          -- singleton we grab isn't already running (which is a simple existence check, since
          -- the unique indexes ensure there is at most one singleton running, and one queued)
          update_query := 'UPDATE delayed_jobs SET next_in_strand=true WHERE id IN (
            SELECT id FROM delayed_jobs j2
              WHERE next_in_strand=false AND
                j2.strand=$1.strand AND
                (j2.singleton IS NULL OR NOT EXISTS (SELECT 1 FROM delayed_jobs j3 WHERE j3.singleton=j2.singleton AND j3.id<>j2.id AND (j3.locked_by IS NULL OR j3.locked_by IS NOT NULL)))
              ORDER BY j2.strand_order_override ASC, j2.id ASC
              LIMIT ';

          IF should_be_precise THEN
            running_count := (SELECT COUNT(*) FROM (
              SELECT 1 FROM delayed_jobs WHERE strand = OLD.strand AND next_in_strand = 't' LIMIT OLD.max_concurrent
            ) s);
            IF running_count < OLD.max_concurrent THEN
              update_query := update_query || '($1.max_concurrent - $2)';
            ELSE
              -- we have too many running already; just bail
              RETURN OLD;
            END IF;
          ELSE
            update_query := update_query || '1';

            -- n-strands don't require precise ordering; we can make this query more performant
            IF OLD.max_concurrent > 1 THEN
              skip_locked := ' SKIP LOCKED';
            END IF;
          END IF;

          update_query := update_query || ' FOR UPDATE' || COALESCE(skip_locked, '') || ')';
          EXECUTE update_query USING OLD, running_count;
        END IF;

        IF OLD.singleton IS NOT NULL THEN
          PERFORM pg_advisory_xact_lock(half_md5_as_bigint(CONCAT('singleton:', OLD.singleton)));

          transition := EXISTS (SELECT 1 FROM delayed_jobs AS j1 WHERE j1.singleton = OLD.singleton AND j1.strand IS DISTINCT FROM OLD.strand AND locked_by IS NULL);

          IF transition THEN
            next_strand := (SELECT j1.strand FROM delayed_jobs AS j1 WHERE j1.singleton = OLD.singleton AND j1.strand IS DISTINCT FROM OLD.strand AND locked_by IS NULL AND j1.strand IS NOT NULL LIMIT 1);

            IF next_strand IS NOT NULL THEN
              -- if the singleton has a new strand defined, we need to lock it to ensure we obey n_strand constraints --
              IF NOT pg_try_advisory_xact_lock(half_md5_as_bigint(next_strand)) THEN
                -- a failure to acquire the lock means that another process already has it and will thus handle this singleton --
                RETURN OLD;
              END IF;
            END IF;
          ELSIF OLD.strand IS NOT NULL THEN
            -- if there is no transition and there is a strand then we have already handled this singleton in the case above --
            RETURN OLD;
          END IF;

          -- handles transitioning a singleton from stranded to not stranded --
          -- handles transitioning a singleton from unstranded to stranded --
          -- handles transitioning a singleton from strand A to strand B --
          -- these transitions are a relatively rare case, so we take a shortcut and --
          -- only start the next singleton if its strand does not currently have any running jobs --
          -- if it does, the next stranded job that finishes will start this singleton if it can --
          UPDATE delayed_jobs SET next_in_strand=true WHERE id IN (
            SELECT id FROM delayed_jobs j2
              WHERE next_in_strand=false AND
                j2.singleton=OLD.singleton AND
                j2.locked_by IS NULL AND
                (j2.strand IS NULL OR NOT EXISTS (SELECT 1 FROM delayed_jobs j3 WHERE j3.strand=j2.strand AND j3.id<>j2.id))
              FOR UPDATE
            );
        END IF;
        RETURN OLD;
      END;
      $$ LANGUAGE plpgsql SET search_path TO #{::Switchman::Shard.current.name};
    SQL
  end
end
# rubocop:enable Rails/SquishedSQLHeredocs
