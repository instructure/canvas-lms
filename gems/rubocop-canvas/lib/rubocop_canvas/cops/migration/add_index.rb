# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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
      class AddIndex < Cop
        include RuboCop::Canvas::NewTables
        include RuboCop::Canvas::CurrentDef
        include RuboCop::Canvas::NonTransactional

        NON_TRANSACTIONAL_MSG = "Use `disable_ddl_transaction!` in the migration class when adding an index to an existing table."
        ALGORITHM_CONCURRENTLY_MSG = "Use the `algorithm: :concurrently` kwarg option when adding an index to an existing table."
        INDEX_ALGORITHM_CONCURRENTLY_MSG = "Use `index: { algorithm: :concurrently }` when adding an index to an existing table with `add_reference`"

        def_node_matcher :add_index, <<~PATTERN
          (send nil? :add_index $_ ...)
        PATTERN

        def_node_matcher :add_reference, <<~PATTERN
          (send nil? :add_reference $_ ...)
        PATTERN

        def_node_search :algorithm_concurrently?, <<~PATTERN
          (pair (sym :algorithm) (sym :concurrently))
        PATTERN

        def_node_search :index_argument, <<~PATTERN
          (pair (sym :index) $_)
        PATTERN

        def_node_matcher :false?, <<~PATTERN
          (false)
        PATTERN

        def_node_matcher :change_table, <<~PATTERN
          (block (send nil? :change_table $_ ...) ...)
        PATTERN

        def_node_search :ct_index, <<~PATTERN
          $(send lvar :index ...)
        PATTERN

        def_node_search :ct_references, <<~PATTERN
          $(send lvar :references ...)
        PATTERN

        def on_class(node)
          @class_node = node
          @non_transactional = non_transactional?(node)
          @new_tables = new_tables(node)
        end

        RESTRICT_ON_SEND = %i[add_index add_reference].freeze

        def on_send(node)
          return if @current_def == :down

          if (table_arg = add_index(node)) && !@new_tables.include?(table_arg.indifferent)
            check_add_index(node)
          elsif (table_arg = add_reference(node)) && !@new_tables.include?(table_arg.indifferent)
            check_add_reference(node)
          end
        end

        def on_block(node)
          return if @current_def == :down

          # it'd be weird to call `create_table` and `change_table` in the same migration, but ¯\_(ツ)_/¯
          if (table_arg = change_table(node)) && !@new_tables.include?(table_arg.indifferent)
            check_change_table(node)
          end
        end

        def check_non_transactional
          if @class_node && !@non_transactional && !@already_nagged_about_this
            add_offense @class_node, message: NON_TRANSACTIONAL_MSG, severity: :warning
            @already_nagged_about_this = true
          end
        end

        def check_add_index(node)
          check_non_transactional

          unless algorithm_concurrently?(node)
            add_offense node, message: ALGORITHM_CONCURRENTLY_MSG, severity: :warning
          end
        end

        def check_add_reference(node)
          arg = index_argument(node).first
          if arg.nil? || !false?(arg)
            check_non_transactional
            if arg.nil? || !algorithm_concurrently?(arg)
              add_offense arg || node, message: INDEX_ALGORITHM_CONCURRENTLY_MSG, severity: :warning
            end
          end
        end

        def check_change_table(node)
          ct_index(node).each { |subnode| check_add_index(subnode) }
          ct_references(node).each { |subnode| check_add_reference(subnode) }
        end
      end
    end
  end
end
