# frozen_string_literal: true

class SpeedUpMaxConcurrentDeleteTrigger < ActiveRecord::Migration[4.2]
  tag :predeploy

  def connection
    Delayed::Job.connection
  end

  def up
    if connection.adapter_name == 'PostgreSQL'
      search_path = Shard.current.name
      # tl;dr sacrifice some responsiveness to max_concurrent changes for faster performance
      # don't get the count every single time - it's usually safe to just set the next one in line
      # since the max_concurrent doesn't change all that often for a strand
      execute(<<-SQL)
        CREATE OR REPLACE FUNCTION #{connection.quote_table_name('delayed_jobs_after_delete_row_tr_fn')} () RETURNS trigger AS $$
        DECLARE
          running_count integer;
          should_lock boolean;
          should_be_precise boolean;
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
        
            IF should_be_precise THEN
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
              -- n-strands don't require precise ordering; we can make this query more performant
              IF OLD.max_concurrent > 1 THEN
                UPDATE delayed_jobs SET next_in_strand = 't' WHERE id =
                (SELECT id FROM delayed_jobs j2 WHERE next_in_strand = 'f' AND
                  j2.strand = OLD.strand ORDER BY j2.id ASC LIMIT 1 FOR UPDATE SKIP LOCKED);
              ELSE
                UPDATE delayed_jobs SET next_in_strand = 't' WHERE id =
                  (SELECT id FROM delayed_jobs j2 WHERE next_in_strand = 'f' AND
                    j2.strand = OLD.strand ORDER BY j2.id ASC LIMIT 1 FOR UPDATE);
              END IF;
            END IF;
          END IF;
          RETURN OLD;
        END;
        $$ LANGUAGE plpgsql SET search_path TO #{search_path};
      SQL
    end
  end

  def down
    if connection.adapter_name == 'PostgreSQL'
      search_path = Shard.current.name
      execute(<<-SQL)
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
      SQL
    end
  end
end

