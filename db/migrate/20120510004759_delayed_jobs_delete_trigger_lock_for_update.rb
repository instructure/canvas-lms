class DelayedJobsDeleteTriggerLockForUpdate < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.connection
    Delayed::Backend::ActiveRecord::Job.connection
  end

  def self.up
    if connection.adapter_name == 'PostgreSQL'
      execute(<<-CODE)
      CREATE OR REPLACE FUNCTION #{connection.quote_table_name('delayed_jobs_after_delete_row_tr_fn')} () RETURNS trigger AS $$
      BEGIN
        UPDATE delayed_jobs SET next_in_strand = 't' WHERE id = (SELECT id FROM delayed_jobs j2 WHERE j2.strand = OLD.strand ORDER BY j2.strand, j2.id ASC LIMIT 1 FOR UPDATE);
        RETURN OLD;
      END;
      $$ LANGUAGE plpgsql;
      CODE
    end
  end

  def self.down
    if connection.adapter_name == 'PostgreSQL'
      execute(<<-CODE)
      CREATE OR REPLACE FUNCTION  #{connection.quote_table_name('delayed_jobs_after_delete_row_tr_fn')} () RETURNS trigger AS $$
      BEGIN
        UPDATE delayed_jobs SET next_in_strand = 't' WHERE id = (SELECT id FROM delayed_jobs j2 WHERE j2.strand = OLD.strand ORDER BY j2.strand, j2.id ASC LIMIT 1);
        RETURN OLD;
      END;
      $$ LANGUAGE plpgsql;
      CODE
    end
  end
end
