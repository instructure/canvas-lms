class DropPsqlJobsPopFn < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.connection
    Delayed::Job.connection
  end

  def self.up
    if connection.adapter_name == 'PostgreSQL'
      connection.execute("DROP FUNCTION IF EXISTS pop_from_delayed_jobs(varchar, varchar, integer, integer, timestamp without time zone)")
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
