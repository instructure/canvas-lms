# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

module DataFixup
  class DataFixupGenerator < Rails::Generators::NamedBase
    MIGRATION_PREFIX = "data_fixup"

    source_root File.expand_path("templates", __dir__)

    def create_data_fixup_file
      generate_migration
      generate_data_fixup
      generate_data_fixup_spec
      overwrite_migration_with_template
    end

    def generate_data_fixup_spec
      template "data_fixup_spec.erb", Rails.root.join("spec/lib/data_fixup", "#{file_name}_spec.rb")
    end

    private

    def migration_file
      @migration_file ||= Rails.root.glob("db/migrate/*_#{MIGRATION_PREFIX}_#{file_name}.rb").max_by { |f| File.mtime(f) }
    end

    def generate_migration
      generate "migration", "#{MIGRATION_PREFIX}_#{file_name}"
    end

    def generate_data_fixup
      template "data_fixup.erb", Rails.root.join("lib/data_fixup", "#{file_name}.rb")
    end

    def overwrite_migration_with_template
      @migration_class_name = "DataFixup#{class_name}"
      @migration_version = ActiveRecord::VERSION::STRING.to_f
      @datafixup_class_name = class_name

      template "#{MIGRATION_PREFIX}_migration.erb", migration_file.to_s, force: true
    end
  end
end
