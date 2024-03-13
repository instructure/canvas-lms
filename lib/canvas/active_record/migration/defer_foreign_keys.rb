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

module Canvas
  module ActiveRecord
    module Migration
      # Prepend this module into your migration to automatically defer
      # creation of foreign keys until the end of the migration if the table
      # they reference has not yet been created (and will be later in the migration)
      module DeferForeignKeys
        module TableDefinition
          def references(*args, foreign_key: false, **options)
            super

            if foreign_key
              column = columns.last
              to_table = column.foreign_key[:to_table]
              unless @migration.created_tables.include?(to_table.to_s)
                @migration.deferred_foreign_keys << [name, column.foreign_key]
                column.foreign_key = nil
              end
            end
          end

          def foreign_key(to_table, **options)
            super

            fk = foreign_keys.last
            unless @migration.created_tables.include?(fk.to_table)
              foreign_keys.pop
              @migration.deferred_foreign_keys << [name, fk.options.merge(to_table: fk.to_table)]
            end
          end
        end
        private_constant :TableDefinition

        def self.prepended(klass)
          klass.attr_reader :created_tables, :deferred_foreign_keys
          super
        end

        def initialize(...)
          @created_tables = Set.new
          @deferred_foreign_keys = []
          super
        end

        def up
          super

          deferred_foreign_keys.each do |table, foreign_key|
            add_foreign_key(table, foreign_key[:to_table], **foreign_key)
          end
        end

        private

        def compatible_table_definition(table_definition)
          class << table_definition
            prepend TableDefinition
          end
          created_tables << table_definition.name
          table_definition.instance_variable_set(:@migration, self)
          super
        end
      end
    end
  end
end
