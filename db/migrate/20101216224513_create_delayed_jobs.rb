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

class CreateDelayedJobs < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    create_table :delayed_jobs do |table|
      # Allows some jobs to jump to the front of the queue
      table.integer  :priority, default: 0
      # Provides for retries, but still fail eventually.
      table.integer  :attempts, default: 0
      # YAML-encoded string of the object that will do work
      table.text     :handler
      # reason for last failure (See Note below)
      table.text     :last_error
      # The queue that this job is in
      table.string   :queue, limit: 255
      # When to run.
      # Could be Time.zone.now for immediately, or sometime in the future.
      table.datetime :run_at
      # Set when a client is working on this object
      table.datetime :locked_at
      # Set when all retries have failed
      table.datetime :failed_at
      # Who is working on this object (if locked)
      table.string   :locked_by, limit: 255

      table.timestamps

      table.string   :tag, limit: 255
      table.integer  :max_attempts
      table.string   :strand, limit: 255
      table.boolean  :next_in_strand, default: true, null: false
      table.integer  :shard_id, limit: 8
      table.string   :source, limit: 255
      table.integer  :max_concurrent, default: 1, null: false
      table.datetime :expires_at
    end

    connection.execute("CREATE INDEX get_delayed_jobs_index ON #{connection.quote_table_name(Delayed::Job.table_name)} (priority, run_at) WHERE locked_at IS NULL AND queue = 'canvas_queue' AND next_in_strand = 't'")
    add_index :delayed_jobs, [:tag]
    add_index :delayed_jobs, %w[strand id], name: "index_delayed_jobs_on_strand"
    add_index :delayed_jobs, :locked_by, where: "locked_by IS NOT NULL"
    add_index :delayed_jobs, %w[run_at tag]
    add_index :delayed_jobs, :shard_id

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
          IF (SELECT COUNT(*) FROM delayed_jobs WHERE strand = NEW.strand) >= NEW.max_concurrent THEN
            NEW.next_in_strand := 'f';
          END IF;
        END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql SET search_path TO #{search_path};
    SQL
    execute("CREATE TRIGGER delayed_jobs_before_insert_row_tr BEFORE INSERT ON #{connection.quote_table_name(Delayed::Job.table_name)} FOR EACH ROW WHEN (NEW.strand IS NOT NULL) EXECUTE PROCEDURE #{connection.quote_table_name("delayed_jobs_before_insert_row_tr_fn")}()")

    # create the delete trigger
    execute(<<~SQL) # rubocop:disable Rails/SquishedSQLHeredocs
      CREATE FUNCTION #{connection.quote_table_name("delayed_jobs_after_delete_row_tr_fn")} () RETURNS trigger AS $$
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
    SQL
    execute("CREATE TRIGGER delayed_jobs_after_delete_row_tr AFTER DELETE ON #{connection.quote_table_name(Delayed::Job.table_name)} FOR EACH ROW WHEN (OLD.strand IS NOT NULL AND OLD.next_in_strand = 't') EXECUTE PROCEDURE #{connection.quote_table_name("delayed_jobs_after_delete_row_tr_fn")}()")

    create_table :failed_jobs do |t|
      t.integer  "priority",    default: 0
      t.integer  "attempts",    default: 0
      t.string   "handler",     limit: 512_000
      t.text     "last_error"
      t.string   "queue", limit: 255
      t.datetime "run_at"
      t.datetime "locked_at"
      t.datetime "failed_at"
      t.string   "locked_by", limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "tag", limit: 255
      t.integer  "max_attempts"
      t.string   "strand", limit: 255
      t.integer  "shard_id", limit: 8
      t.integer  "original_job_id", limit: 8
      t.string   "source", limit: 255
      t.datetime "expires_at"
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
