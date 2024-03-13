# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

# rubocop:disable Migration/Execute, Migration/RootAccountId
class CreateDelayedJobs < ActiveRecord::Migration[7.0]
  tag :predeploy

  def up
    create_table :delayed_jobs do |t|
      # Allows some jobs to jump to the front of the queue
      t.integer :priority, default: 0
      # Provides for retries, but still fail eventually.
      t.integer :attempts, default: 0
      # YAML-encoded string of the object that will do work
      t.text :handler
      # reason for last failure (See Note below)
      t.text :last_error
      # The queue that this job is in
      t.string :queue, limit: 255, null: false
      # When to run.
      # Could be Time.zone.now for immediately, or sometime in the future.
      t.timestamp :run_at, null: false
      # Set when a client is working on this object
      t.timestamp :locked_at
      # Set when all retries have failed
      t.timestamp :failed_at
      # Who is working on this object (if locked)
      t.string :locked_by, limit: 255, index: { where: "locked_by IS NOT NULL" }

      t.timestamps precision: nil

      t.string :tag, limit: 255, index: true
      t.integer :max_attempts
      t.string :strand, limit: 255
      t.boolean :next_in_strand, default: true, null: false
      t.bigint :shard_id, index: true
      t.string :source, limit: 255
      t.integer :max_concurrent, default: 1, null: false
      t.timestamp :expires_at
      t.integer :strand_order_override, default: 0, null: false
      t.string :singleton, index: { where: "singleton IS NOT NULL AND (locked_by IS NULL OR locked_by = '#{::Delayed::Backend::Base::ON_HOLD_LOCKED_BY}')",
                                    unique: true,
                                    name: "index_delayed_jobs_on_singleton_not_running" }

      t.index %i[priority run_at id],
              where: "queue = 'canvas_queue' AND locked_at IS NULL AND next_in_strand",
              name: "get_delayed_jobs_index"
      t.index %i[strand id], name: "index_delayed_jobs_on_strand"
      t.index %i[run_at tag]
      t.index               %i[strand strand_order_override id],
                            where: "strand IS NOT NULL",
                            name: "next_in_strand_index"
      t.index %i[strand next_in_strand id],
              name: "n_strand_index",
              where: "strand IS NOT NULL"
      t.index :singleton,
              where: "singleton IS NOT NULL AND locked_by IS NOT NULL AND locked_by <> '#{::Delayed::Backend::Base::ON_HOLD_LOCKED_BY}'",
              unique: true,
              name: "index_delayed_jobs_on_singleton_running"
    end

    search_path = Shard.current.name

    # use an advisory lock based on the name of the strand, instead of locking the whole table
    # note that we're using half of the md5, so collisions are possible, but we don't really
    # care because that would just be the old behavior, whereas for the most part locking will
    # be much smaller
    execute(<<~SQL) # rubocop:disable Rails/SquishedSQLHeredocs
      CREATE FUNCTION #{connection.quote_table_name("half_md5_as_bigint")}(strand varchar) RETURNS bigint AS $$
        DECLARE
          strand_md5 bytea;
        BEGIN
          strand_md5 := decode(md5(strand), 'hex');
          RETURN (CAST(get_byte(strand_md5, 0) AS bigint) << 56) +
                                    (CAST(get_byte(strand_md5, 1) AS bigint) << 48) +
                                    (CAST(get_byte(strand_md5, 2) AS bigint) << 40) +
                                    (CAST(get_byte(strand_md5, 3) AS bigint) << 32) +
                                    (CAST(get_byte(strand_md5, 4) AS bigint) << 24) +
                                    (get_byte(strand_md5, 5) << 16) +
                                    (get_byte(strand_md5, 6) << 8) +
                                     get_byte(strand_md5, 7);
        END;
        $$ LANGUAGE plpgsql SET search_path TO #{search_path};
    SQL

    # create the insert trigger
    execute(<<~SQL) # rubocop:disable Rails/SquishedSQLHeredocs
      CREATE FUNCTION #{connection.quote_table_name("delayed_jobs_before_insert_row_tr_fn")} () RETURNS trigger AS $$
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
          PERFORM 1 FROM delayed_jobs WHERE singleton = NEW.singleton AND (locked_by IS NULL OR locked_by = '#{::Delayed::Backend::Base::ON_HOLD_LOCKED_BY}' OR locked_by <> '#{::Delayed::Backend::Base::ON_HOLD_LOCKED_BY}');
          IF FOUND THEN
            NEW.next_in_strand := false;
          END IF;
        END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql SET search_path TO #{::Switchman::Shard.current.name};
    SQL
    execute("CREATE TRIGGER delayed_jobs_before_insert_row_tr BEFORE INSERT ON #{connection.quote_table_name(Delayed::Job.table_name)} FOR EACH ROW WHEN (NEW.strand IS NOT NULL OR NEW.singleton IS NOT NULL) EXECUTE PROCEDURE #{connection.quote_table_name("delayed_jobs_before_insert_row_tr_fn")}()")

    # create the delete trigger
    execute(<<~SQL) # rubocop:disable Rails/SquishedSQLHeredocs
      CREATE FUNCTION #{connection.quote_table_name("delayed_jobs_after_delete_row_tr_fn")} () RETURNS trigger AS $$
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
    execute("CREATE TRIGGER delayed_jobs_after_delete_row_tr AFTER DELETE ON #{connection.quote_table_name(Delayed::Job.table_name)} FOR EACH ROW WHEN ((OLD.strand IS NOT NULL OR OLD.singleton IS NOT NULL) AND OLD.next_in_strand=true) EXECUTE PROCEDURE #{connection.quote_table_name("delayed_jobs_after_delete_row_tr_fn")}()")

    execute(<<~SQL) # rubocop:disable Rails/SquishedSQLHeredocs
      CREATE FUNCTION #{connection.quote_table_name("delayed_jobs_before_unlock_delete_conflicting_singletons_row_fn")} () RETURNS trigger AS $$
      BEGIN
        DELETE FROM delayed_jobs WHERE id<>OLD.id AND singleton=OLD.singleton AND locked_by IS NULL;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql SET search_path TO #{::Switchman::Shard.current.name};
    SQL
    execute(<<~SQL) # rubocop:disable Rails/SquishedSQLHeredocs
      CREATE TRIGGER delayed_jobs_before_unlock_delete_conflicting_singletons_row_tr BEFORE UPDATE ON #{connection.quote_table_name(Delayed::Job.table_name)} FOR EACH ROW WHEN (
        OLD.singleton IS NOT NULL AND
        OLD.singleton=NEW.singleton AND
        OLD.locked_by IS NOT NULL AND
        NEW.locked_by IS NULL) EXECUTE PROCEDURE #{connection.quote_table_name("delayed_jobs_before_unlock_delete_conflicting_singletons_row_fn")}();
    SQL

    create_table :failed_jobs do |t|
      t.integer :priority, default: 0
      t.integer :attempts, default: 0
      t.text :handler
      t.text :last_error
      t.string :queue, limit: 255
      t.timestamp :run_at
      t.timestamp :locked_at
      t.timestamp :failed_at, index: true
      t.string :locked_by, limit: 255
      t.timestamps null: true, precision: nil
      t.string :tag, limit: 255, index: true
      t.integer :max_attempts
      t.string :strand, limit: 255, index: { where: "strand IS NOT NULL" }
      # This column exists in switchman-inst-jobs, although not in Canvas. For the purposes of this migration, mirror
      # the lack of a WHERE constraint to mirror switchman-inst-jobs to prevent any surprises later.
      t.bigint :shard_id, index: true
      t.bigint :original_job_id
      t.string :source, limit: 255
      t.timestamp :expires_at
      t.integer :strand_order_override, default: 0, null: false
      t.string :singleton, index: { where: "singleton IS NOT NULL" }
      t.bigint :requeued_job_id
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
# rubocop:enable Migration/Execute, Migration/RootAccountId
