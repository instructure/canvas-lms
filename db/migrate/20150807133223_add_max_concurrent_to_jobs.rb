class AddMaxConcurrentToJobs < ActiveRecord::Migration[4.2]
  tag :predeploy

  def connection
    Delayed::Backend::ActiveRecord::Job.connection
  end

  def up
    add_column :delayed_jobs, :max_concurrent, :integer, :default => 1, :null => false

    if connection.adapter_name == 'PostgreSQL'
      search_path = Shard.current.name

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
      $$ LANGUAGE plpgsql SET search_path TO #{search_path};
      CODE

      execute(<<-CODE)
      CREATE OR REPLACE FUNCTION #{connection.quote_table_name('delayed_jobs_after_delete_row_tr_fn')} () RETURNS trigger AS $$
      BEGIN
        IF OLD.strand IS NOT NULL THEN
          PERFORM pg_advisory_xact_lock(half_md5_as_bigint(OLD.strand));
          IF (SELECT COUNT(*) FROM delayed_jobs WHERE strand = OLD.strand AND next_in_strand = 't') < OLD.max_concurrent THEN
            UPDATE delayed_jobs SET next_in_strand = 't' WHERE id = (
              SELECT id FROM delayed_jobs j2 WHERE next_in_strand = 'f' AND
              j2.strand = OLD.strand ORDER BY j2.id ASC LIMIT 1 FOR UPDATE
            );
          END IF;
        END IF;
        RETURN OLD;
      END;
      $$ LANGUAGE plpgsql SET search_path TO #{search_path};
      CODE
    end
  end

  def down
    remove_column :delayed_jobs, :max_concurrent

    if connection.adapter_name == 'PostgreSQL'
      search_path = Shard.current.name

      execute(<<-CODE)
      CREATE OR REPLACE FUNCTION #{connection.quote_table_name('delayed_jobs_before_insert_row_tr_fn')} () RETURNS trigger AS $$
      BEGIN
        PERFORM pg_advisory_xact_lock(half_md5_as_bigint(NEW.strand));
        IF (SELECT 1 FROM delayed_jobs WHERE strand = NEW.strand LIMIT 1) = 1 THEN
          NEW.next_in_strand := 'f';
        END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql SET search_path TO #{search_path};
      CODE

      execute(<<-CODE)
      CREATE OR REPLACE FUNCTION #{connection.quote_table_name('delayed_jobs_after_delete_row_tr_fn')} () RETURNS trigger AS $$
      BEGIN
        PERFORM pg_advisory_xact_lock(half_md5_as_bigint(OLD.strand));
        UPDATE delayed_jobs SET next_in_strand = 't' WHERE id = (SELECT id FROM delayed_jobs j2 WHERE j2.strand = OLD.strand ORDER BY j2.strand, j2.id ASC LIMIT 1 FOR UPDATE);
        RETURN OLD;
      END;
      $$ LANGUAGE plpgsql SET search_path TO #{search_path};
      CODE
    end
  end
end
