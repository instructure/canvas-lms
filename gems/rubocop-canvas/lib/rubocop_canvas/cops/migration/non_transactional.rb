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
      class NonTransactional < Base
        include RuboCop::Canvas::CurrentDef
        include RuboCop::Canvas::NonTransactional

        def on_class(node)
          @class_node = node
          @non_transactional = non_transactional?(node)
        end

        RESTRICT_ON_SEND = %i[add_index add_column add_foreign_key add_reference create_table remove_foreign_key remove_index drop_table].freeze

        def on_send(node)
          _receiver, method_name = *node

          case method_name
          when :add_index
            check_add_index(node)
          when :add_reference
            check_add_reference(node)
          when :add_column, :add_foreign_key, :create_table
            check_if_not_exists(node)
          when :remove_column, :remove_foreign_key, :remove_index, :drop_table
            check_if_exists(node)
          end
        end

        def_node_matcher :create_table, <<~PATTERN
          (block (send nil? :create_table $_ ...) ...)
        PATTERN

        def_node_matcher :change_table, <<~PATTERN
          (block (send nil? :change_table $_ ...) ...)
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

        def_node_search :if_not_exists?, <<~PATTERN
          (pair (sym :if_not_exists) true)
        PATTERN

        def_node_search :if_exists?, <<~PATTERN
          (pair (sym :if_exists) true)
        PATTERN

        def_node_search :ct_column, <<~PATTERN
          $(send lvar {:column :foreign_key :bigint :binary :boolean :date :datetime :decimal :float :integer :json :string :text :time :timestamp :virtual :blob :numeric} ...)
        PATTERN

        def_node_search :ct_index, <<~PATTERN
          $(send lvar :index ...)
        PATTERN

        def_node_search :ct_references, <<~PATTERN
          $(send lvar :references ...)
        PATTERN

        def_node_search :ct_removal, <<~PATTERN
          $(send lvar {:remove :remove_index} ...)
        PATTERN

        def_node_matcher :unless_exists_conditional?, <<~PATTERN
          ^(if (send _ {:column_exists? :index_exists? :foreign_key_exists? :check_constraint_exists?} _) nil? _)
        PATTERN

        def_node_matcher :if_exists_conditional?, <<~PATTERN
          ^(if (send _ {:column_exists? :index_exists? :foreign_key_exists? :check_constraint_exists?} _) _ nil?)
        PATTERN

        def on_block(node)
          if create_table(node)
            check_batch_table_ops(node)
          elsif change_table(node)
            @in_change_table = true
            check_batch_table_ops(node)
            @in_change_table = false
          end
        end

        def check_add_reference(node)
          arg = index_argument(node).first
          if arg.nil? || !false?(arg)
            check_add_index(arg || node)
          end
        end

        def check_add_index(node)
          if algorithm_concurrently?(node) && !@non_transactional
            add_offense(node,
                        message: "Concurrent index adds require `disable_ddl_transaction!`",
                        severity: :error)
          end

          check_if_not_exists(node)
        end

        def check_if_not_exists(node)
          if @in_change_table
            if if_not_exists?(node)
              add_offense(node,
                          message: "Inside batch table operations, use `unless t.column_exists?(:name)` not `if_not_exists: true`",
                          severity: :error)
            end
            unless unless_exists_conditional?(node)
              add_offense(node,
                          message: "Non-transactional migrations should be idempotent; add `unless t.column_exists?(:name)` or equivalent",
                          severity: :error)
            end
          elsif @non_transactional && !if_not_exists?(node)
            add_offense(node,
                        message: "Non-transactional migrations should be idempotent; add `if_not_exists: true`",
                        severity: :error)
          end
        end

        def check_if_exists(node)
          if @in_change_table
            if if_exists?(node)
              add_offense(node,
                          message: "Inside batch table operations, use `if t.column_exists?(:name)` not `if_exists: true`",
                          severity: :error)
            end
            unless if_exists_conditional?(node)
              add_offense(node,
                          message: "Non-transactional migrations should be idempotent; add `if t.column_exists?(:name)` or equivalent",
                          severity: :error)
            end
          elsif @non_transactional && !if_exists?(node)
            add_offense(node,
                        message: "Non-transactional migrations should be idempotent; add `if_exists: true`",
                        severity: :error)
          end
        end

        def check_batch_table_ops(node)
          ct_index(node).each { |subnode| check_add_index(subnode) }
          ct_references(node).each { |subnode| check_add_reference(subnode) }
          ct_column(node).each { |subnode| check_if_not_exists(subnode) }
          ct_removal(node).each { |subnode| check_if_exists(subnode) }
        end
      end
    end
  end
end
