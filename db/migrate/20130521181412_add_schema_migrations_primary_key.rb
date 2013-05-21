class AddSchemaMigrationsPrimaryKey < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    case connection.adapter_name
      when 'PostgreSQL'
        execute("ALTER TABLE schema_migrations ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY USING INDEX unique_schema_migrations")
      when 'MySQL', 'Mysql2'
        execute("ALTER TABLE schema_migrations ADD PRIMARY KEY (version)")
        remove_index :schema_migrations, :name => 'unique_schema_migrations'
    end
  end

  def self.down
    case connection.adapter_name
      when 'PostgreSQL'
        execute("ALTER TABLE schema_migrations DROP CONSTRAINT schema_migrations_pkey")
        add_index :schema_migrations, :version, :unique => true, :name => 'unique_schema_migrations'
      when 'MySQL', 'Mysql2'
        execute("ALTER TABLE schema_migrations DROP PRIMARY KEY")
        add_index :schema_migrations, :version, :unique => true, :name => 'unique_schema_migrations'
    end
  end
end
