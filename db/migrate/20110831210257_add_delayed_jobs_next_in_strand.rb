class AddDelayedJobsNextInStrand < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.connection
    Delayed::Backend::ActiveRecord::Job.connection
  end

  def self.up
    raise("#{connection.adapter_name} is not supported for delayed jobs queue") unless %w(PostgreSQL MySQL Mysql2 SQLite).include?(connection.adapter_name)

    remove_index :delayed_jobs, :name => 'index_delayed_jobs_for_get_next'

    add_column :delayed_jobs, :next_in_strand, :boolean, :default => true, :null => false

    # create the new index
    case connection.adapter_name
    when 'PostgreSQL'
      connection.execute("CREATE INDEX get_delayed_jobs_index ON #{Delayed::Backend::ActiveRecord::Job.quoted_table_name} (priority, run_at) WHERE locked_at IS NULL AND queue = 'canvas_queue' AND next_in_strand = 't'")
    else
      add_index :delayed_jobs, %w(priority run_at locked_at queue next_in_strand), :name => 'get_delayed_jobs_index'
    end

    # create the insert trigger
    case connection.adapter_name
    when 'PostgreSQL'
      execute(<<-CODE)
      CREATE FUNCTION #{connection.quote_table_name('delayed_jobs_before_insert_row_tr_fn')} () RETURNS trigger AS $$
      BEGIN
        LOCK delayed_jobs IN SHARE ROW EXCLUSIVE MODE;
        IF (SELECT 1 FROM delayed_jobs WHERE strand = NEW.strand LIMIT 1) = 1 THEN
          NEW.next_in_strand := 'f';
        END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
      CODE
      execute("CREATE TRIGGER delayed_jobs_before_insert_row_tr BEFORE INSERT ON #{Delayed::Backend::ActiveRecord::Job.quoted_table_name} FOR EACH ROW WHEN (NEW.strand IS NOT NULL) EXECUTE PROCEDURE #{connection.quote_table_name('delayed_jobs_before_insert_row_tr_fn')}()")
    when 'MySQL', 'Mysql2'
      execute(<<-CODE)
      CREATE TRIGGER delayed_jobs_before_insert_row_tr BEFORE INSERT ON delayed_jobs
      FOR EACH ROW
      BEGIN
        IF NEW.strand IS NOT NULL THEN
          IF (SELECT 1 FROM delayed_jobs WHERE strand = NEW.strand LIMIT 1) = 1 THEN
            SET NEW.next_in_strand = 0;
          END IF;
        END IF;
      END;
      CODE
    when 'SQLite'
      execute(<<-CODE)
      CREATE TRIGGER delayed_jobs_after_insert_row_tr AFTER INSERT ON delayed_jobs
      FOR EACH ROW WHEN (NEW.strand IS NOT NULL)
      BEGIN
        UPDATE delayed_jobs SET next_in_strand = 0 WHERE id = NEW.id AND id <> (SELECT id FROM delayed_jobs j2 WHERE j2.strand = NEW.strand ORDER BY j2.strand, j2.id ASC LIMIT 1);
      END;
      CODE
    end

    # create the delete trigger
    case connection.adapter_name
    when 'PostgreSQL'
      execute(<<-CODE)
      CREATE FUNCTION #{connection.quote_table_name('delayed_jobs_after_delete_row_tr_fn')} () RETURNS trigger AS $$
      BEGIN
        UPDATE delayed_jobs SET next_in_strand = 't' WHERE id = (SELECT id FROM delayed_jobs j2 WHERE j2.strand = OLD.strand ORDER BY j2.strand, j2.id ASC LIMIT 1);
        RETURN OLD;
      END;
      $$ LANGUAGE plpgsql;
      CODE
      execute("CREATE TRIGGER delayed_jobs_after_delete_row_tr AFTER DELETE ON #{Delayed::Backend::ActiveRecord::Job.quoted_table_name} FOR EACH ROW WHEN (OLD.strand IS NOT NULL AND OLD.next_in_strand = 't') EXECUTE PROCEDURE #{connection.quote_table_name('delayed_jobs_after_delete_row_tr_fn')}()")
    when 'MySQL', 'Mysql2'
      # mysql doesn't support modifying the underlying table inside a trigger,
      # so we can't do this here -- we have to use a rails after_destroy
      # callback :/
      # this means that deleting the first job from a strand from
      # outside rails is *not* safe when using mysql for the queue.
      # execute(<<-CODE)
      # CREATE TRIGGER delayed_jobs_after_delete_row_tr AFTER DELETE ON delayed_jobs
      # FOR EACH ROW
      # BEGIN
      #   IF OLD.strand IS NOT NULL THEN
      #     UPDATE delayed_jobs SET next_in_strand = 1 WHERE id = (SELECT id FROM delayed_jobs j2 WHERE j2.strand = OLD.strand ORDER BY j2.strand, j2.id ASC LIMIT 1);
      #   END IF;
      # END;
      # CODE
    when 'SQLite'
      execute(<<-CODE)
      CREATE TRIGGER delayed_jobs_after_delete_row_tr AFTER DELETE ON delayed_jobs
      FOR EACH ROW WHEN (OLD.strand IS NOT NULL AND OLD.next_in_strand = 1)
      BEGIN
        UPDATE delayed_jobs SET next_in_strand = 1 WHERE id = (SELECT id FROM delayed_jobs j2 WHERE j2.strand = OLD.strand ORDER BY j2.strand, j2.id ASC LIMIT 1);
      END;
      CODE
    end

    if %w{MySQL Mysql2}.include?(connection.adapter_name)
      # use temp tables to work around subselect limitations in mysql
      execute(%{CREATE TEMPORARY TABLE dj_20110831210257 (strand varchar(255), next_job_id bigint) SELECT strand, min(id) as next_job_id FROM #{Delayed::Backend::ActiveRecord::Job.quoted_table_name} WHERE strand IS NOT NULL GROUP BY strand})
      update(%{UPDATE #{Delayed::Backend::ActiveRecord::Job.quoted_table_name} SET next_in_strand = #{Delayed::Backend::ActiveRecord::Job.quote_value(false, nil)} WHERE strand IS NOT NULL AND id <> (SELECT t.next_job_id FROM dj_20110831210257 t WHERE t.strand = delayed_jobs.strand)})
      execute(%{DROP TABLE dj_20110831210257})
    else
      update(%{UPDATE #{Delayed::Backend::ActiveRecord::Job.quoted_table_name} SET next_in_strand = #{Delayed::Backend::ActiveRecord::Job.quote_value(false, nil)} WHERE strand IS NOT NULL AND id <> (SELECT id FROM #{Delayed::Backend::ActiveRecord::Job.quoted_table_name} j2 WHERE j2.strand = delayed_jobs.strand ORDER BY j2.strand, j2.id ASC LIMIT 1)})
    end
  end

  def self.down
    case connection.adapter_name
    when 'PostgreSQL'
      execute %{DROP TRIGGER delayed_jobs_before_insert_row_tr ON delayed_jobs}
      execute %{DROP FUNCTION delayed_jobs_before_insert_row_tr_fn()}
      execute %{DROP TRIGGER delayed_jobs_after_delete_row_tr ON delayed_jobs}
      execute %{DROP FUNCTION delayed_jobs_after_delete_row_tr_fn()}
    when 'MySQL', 'Mysql2'
      execute %{DROP TRIGGER delayed_jobs_before_insert_row_tr}
    when 'SQLite'
      execute %{DROP TRIGGER delayed_jobs_after_insert_row_tr}
      execute %{DROP TRIGGER delayed_jobs_after_delete_row_tr}
    end

    remove_column :delayed_jobs, :next_in_strand
    remove_index :delayed_jobs, :name => 'get_delayed_jobs_index'
    add_index :delayed_jobs, %w(run_at queue locked_at strand priority), :name => 'index_delayed_jobs_for_get_next'
  end
end
