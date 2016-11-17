class AddSchemaMigrationsPrimaryKey < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    execute("ALTER TABLE #{connection.quote_table_name('schema_migrations')} ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY USING INDEX unique_schema_migrations")
  end

  def self.down
    execute("ALTER TABLE #{connection.quote_table_name('schema_migrations')} DROP CONSTRAINT schema_migrations_pkey")
    add_index :schema_migrations, :version, :unique => true, :name => 'unique_schema_migrations'
  end
end
