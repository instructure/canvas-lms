class PopJobsWithDbFunctionOnPostgresql < ActiveRecord::Migration
  tag :predeploy

  def self.connection
    Delayed::Job.connection
  end

  def self.up
    if connection.adapter_name == 'PostgreSQL'
      execute(<<-CODE)
      CREATE OR REPLACE FUNCTION pop_from_delayed_jobs (worker_name varchar, queue_name varchar, min_priority integer, max_priority integer, cur_time timestamp without time zone) RETURNS bigint AS $$
      DECLARE
        result_id bigint;
      BEGIN
        IF queue_name IS NULL THEN
          SELECT id FROM delayed_jobs INTO result_id WHERE run_at <= cur_time AND locked_at IS NULL AND next_in_strand = 't' AND priority >= min_priority AND priority <= max_priority AND queue IS NULL ORDER BY priority ASC, run_at ASC LIMIT 1 FOR UPDATE;
        ELSE
          SELECT id FROM delayed_jobs INTO result_id WHERE run_at <= cur_time AND locked_at IS NULL AND next_in_strand = 't' AND priority >= min_priority AND priority <= max_priority AND queue = queue_name ORDER BY priority ASC, run_at ASC LIMIT 1 FOR UPDATE;
        END IF;
        IF result_id IS NULL THEN
          RETURN NULL;
        END IF;

        -- since we did a select FOR UPDATE, this locking should always succeed without contention
        -- however, we still check the return value as a sanity check
        UPDATE delayed_jobs SET locked_at = cur_time, locked_by = worker_name WHERE id = result_id AND locked_at IS NULL AND run_at <= cur_time;
        IF FOUND THEN
          RETURN result_id;
        ELSE
          RETURN null;
        END IF;

      END;
      $$ LANGUAGE plpgsql;
      CODE
    end
  end

  def self.down
    if connection.adapter_name == 'PostgreSQL'
      execute("DROP FUNCTION pop_from_delayed_jobs(varchar, varchar, integer, integer, timestamp without time zone)")
    end
  end
end
