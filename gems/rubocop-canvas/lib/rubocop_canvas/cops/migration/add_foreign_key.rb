# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

module RuboCop
  module Cop
    module Migration
      class AddForeignKey < Cop
        MSG = <<~TEXT
          When adding a foreign key to an existing table, use a non-transactional migration
          and pass `delay_validation: true` (unless the table is known to be small).
        TEXT

        include RuboCop::Canvas::CurrentDef
        include RuboCop::Canvas::NonTransactional
        include RuboCop::Canvas::NewTables

        def_node_matcher :add_foreign_key?, <<~PATTERN
          (send _ :add_foreign_key $_ ...)
        PATTERN

        def_node_search :delay_validation?, <<~PATTERN
          (pair (sym :delay_validation) (true))
        PATTERN

        def on_class(node)
          @new_tables = new_tables(node)
          @non_transactional = non_transactional?(node)
        end

        def on_send(node)
          return if @current_def == :down

          add_foreign_key?(node) do |table_arg|
            if !@new_tables.include?(table_arg.indifferent) && (!@non_transactional || !delay_validation?(node))
              add_offense(node, severity: :warning)
            end
          end
        end
      end
    end
  end
end
