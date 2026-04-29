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

        def create_table(...)
          super do |td|
            yield td if block_given?

            created_tables << td.name

            td.columns.each do |column|
              if (to_table = column.foreign_key&.dig(:to_table)) && !created_tables.include?(to_table.to_s)
                deferred_foreign_keys << [td.name, column.foreign_key]
                column.foreign_key = nil
              end
            end
            td.foreign_keys.reject! do |fk|
              unless created_tables.include?(fk.to_table)
                deferred_foreign_keys << [td.name, fk.options.merge(to_table: fk.to_table)]
                true
              end
            end
          end
        end
      end
    end
  end
end
