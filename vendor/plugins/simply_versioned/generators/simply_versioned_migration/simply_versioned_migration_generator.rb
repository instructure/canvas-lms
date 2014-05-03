unless CANVAS_RAILS2
  require 'rails/generators/active_record'
end

class SimplyVersionedMigrationGenerator < ActiveRecord::Generators::Base
  source_root File.expand_path('../templates', __FILE__)
  def create_migration_file
    migration_template "migration.rb", "db/migrate/#{file_name}.rb"
  end

  def file_name
    "simply_versioned_migration"
  end
end
