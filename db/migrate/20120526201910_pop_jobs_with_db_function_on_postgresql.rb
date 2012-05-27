class PopJobsWithDbFunctionOnPostgresql < ActiveRecord::Migration
  tag :predeploy

  def self.connection
    Delayed::Job.connection
  end

  def self.up
    if connection.adapter_name == 'PostgreSQL'
      Delayed::Job.define_pg_pop_function()
    end
  end

  def self.down
    if connection.adapter_name == 'PostgreSQL'
      Delayed::Job.drop_pg_pop_function()
    end
  end
end
