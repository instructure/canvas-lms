class FixMaxConcurrentTrigger < ActiveRecord::Migration[4.2]
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
    end
  end
end
