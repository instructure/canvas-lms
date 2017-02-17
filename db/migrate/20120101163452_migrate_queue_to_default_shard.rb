class MigrateQueueToDefaultShard < ActiveRecord::Migration[4.2]
  tag :predeploy

  def up
    return unless Shard.current.default?
    return unless ActiveRecord::Base.configurations[Rails.env]['queue']

    db_config = ActiveRecord::Base.configurations[Rails.env].dup
    queue_config = db_config.delete('queue')

    # they're on the same db
    return if db_config == queue_config
    return if ActiveRecord::Base.connection.table_exists?(:delayed_jobs)

    # create the correct schema in the default shard
    migrations = jobs_migrations
    migrations.each do |m|
      next unless ActiveRecord::SchemaMigration.where(version: m.version.to_s).exists?
      m.migrate(:up)
    end

    # now copy stuff over
    queue_conn = ActiveRecord::Base.postgresql_connection(queue_config)

    # lock jobs in case old jobs code is still running
    queue_conn.execute("UPDATE delayed_jobs SET locked_by='queue_migration' WHERE locked_by IS NULL")

    rows = queue_conn.select_all("SELECT * FROM delayed_jobs WHERE locked_by='queue_migration'")
    ActiveRecord::Base.connection.bulk_insert('delayed_jobs', rows)
    table = ActiveRecord::Base.connection.quote_table_name('delayed_jobs')
    ActiveRecord::Base.connection.execute("UPDATE #{table} SET locked_by=NULL WHERE locked_by='queue_migration'")
    seq = ActiveRecord::Base.connection.quote_table_name('delayed_jobs_id_seq')
    ActiveRecord::Base.connection.execute("SELECT setval('#{seq}', (SELECT MAX(id) FROM #{table}))")
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  def jobs_migrations
    jobs = Delayed::Backend::ActiveRecord::Job
    jobs.class_eval do
      class << self
        alias_method :old_connection, :connection
        def connection
          @sentinel
        end
      end
    end
    sentinel = Object.new
    jobs.instance_variable_set(:@sentinel, sentinel)

    migrations = ActiveRecord::Migrator.migrations(ActiveRecord::Migrator.migrations_paths).select do |m|
      m.send(:migration).new.connection == sentinel
    end

    jobs.class_eval do
      class << self
        alias_method :connection, :old_connection
        remove_method :old_connection
      end
    end
    jobs.send(:remove_instance_variable, :@sentinel)

    migrations
  end
end
