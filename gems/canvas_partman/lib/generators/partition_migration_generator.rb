# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

require "active_record"
require "canvas_partman"
require "rails/generators/named_base"
require "rails/generators/active_record"
require "rails/generators/active_record/migration/migration_generator"

class PartitionMigrationGenerator < ActiveRecord::Generators::MigrationGenerator
  source_root File.expand_path("templates", __dir__)

  remove_argument :attributes
  argument :model,
           type: :string,
           required: false,
           desc: "Name of the model whose partitions will be modified."

  def create_migration_file
    unless /^[_a-z0-9]+$/.match?(file_name)
      raise ActiveRecord::IllegalMigrationNameError, file_name
    end

    migration_template "migration.rb.erb",
                       "db/migrate/#{file_name}.#{CanvasPartman.migrations_scope}.rb"
  end

  protected

  def migration_class_name
    name.camelize
  end
end
