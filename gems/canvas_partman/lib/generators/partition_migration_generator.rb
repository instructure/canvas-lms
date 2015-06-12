require 'active_record'
require 'canvas_partman'
require 'rails/generators/named_base'
require 'rails/generators/active_record'
require 'rails/generators/active_record/migration/migration_generator'

class PartitionMigrationGenerator < ActiveRecord::Generators::MigrationGenerator
  source_root File.expand_path("../templates", __FILE__)

  remove_argument :attributes
  argument :model, type: :string, required: false,
    desc: 'Name of the model whose partitions will be modified.'

  def create_migration_file
    unless file_name =~ /^[_a-z0-9]+$/
      raise ActiveRecord::IllegalMigrationNameError.new(file_name)
    end

    migration_template 'migration.rb.erb',
      "db/migrate/#{file_name}.#{CanvasPartman.migrations_scope}.rb"
  end

  protected

  def migration_class_name
    name.camelize
  end
end
