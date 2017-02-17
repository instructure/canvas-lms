class AddSchemaMigrationsPrimaryKey < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    # Rails 5 creates the schema_migrations table with a primary key in the first place;
    # so no need to convert it over
    return unless index_exists?(:schema_migrations, name: 'unique_schema_migrations')
    execute("ALTER TABLE #{connection.quote_table_name('schema_migrations')} ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY USING INDEX unique_schema_migrations")
  end

  def self.down
    execute("ALTER TABLE #{connection.quote_table_name('schema_migrations')} DROP CONSTRAINT schema_migrations_pkey")
    add_index :schema_migrations, :version, :unique => true, :name => 'unique_schema_migrations'
  end
end
