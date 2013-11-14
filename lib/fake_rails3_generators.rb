if CANVAS_RAILS2

module FakeRails3Generators
  # XXX: Rails 2 Compatibility
  require 'rails_generator/base'

  class Base < Rails::Generator::Base

    def self.source_root(path)
      @@source_path = path
    end

    def source_path(relative_source)
      File.join(@@source_path, relative_source)
    end

    def file_name
      @file_name
    end

    def migration_template(source, destination)
      migration_dir = File.dirname(destination)
      @file_name = File.basename(destination).sub(/\.rb$/, '')

      record do |m|
        m.migration_template(source, migration_dir)
      end
    end

    def manifest
      create_migration_file
    end
  end
end

end
