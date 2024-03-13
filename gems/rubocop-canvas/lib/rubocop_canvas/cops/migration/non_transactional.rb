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
      class NonTransactional < Cop
        def on_send(node)
          _receiver, method_name, *args = *node

          case method_name
          when :disable_ddl_transaction!
            @disable_ddl_transaction = true
          when :add_index
            check_add_index(node, args)
          when :add_column, :add_foreign_key
            check_add_column(node, args)
          when :add_reference
            check_add_index(node, args)
            check_reference_args(args)
          when :create_table
            check_create_table(node, args)
          when :remove_foreign_key, :remove_index, :drop_table
            check_remove_foreign_key(node, args)
          end
        end

        ALGORITHM = AST::Node.new(:sym, [:algorithm])
        INDEX = AST::Node.new(:sym, [:index])
        IF_NOT_EXISTS = AST::Node.new(:sym, [:if_not_exists])
        IF_EXISTS = AST::Node.new(:sym, [:if_exists])

        def check_create_table(node, args)
          check_add_index(node, args)

          return unless node.parent.is_a?(RuboCop::AST::BlockNode)

          block_arg = node.parent.arguments.first
          node.parent.body.each_child_node do |child|
            next unless child.send_type? && child.receiver.children.first == block_arg.name

            case child.method_name
            when :references
              check_reference_args(child.arguments)
            when :index
              check_add_index(child, child.arguments)
            end
          end
        end

        def check_reference_args(args)
          options = args.last
          return unless options&.hash_type?

          options.each_pair do |key, value|
            next unless key == INDEX
            next if value.false_type?

            check_add_index(value, [value])
          end
        end

        def check_add_index(node, args)
          options = args.last
          options = nil unless options&.hash_type?

          algorithm = options&.children&.find do |pair|
            pair.children.first == ALGORITHM
          end
          algorithm_name = algorithm&.children&.last&.children&.first

          if algorithm_name == :concurrently && !@disable_ddl_transaction
            add_offense(node,
                        message: "Concurrent index adds require `disable_ddl_transaction!`",
                        severity: :error)
          end

          check_add_column(node, args)
        end

        def check_add_column(node, args)
          options = args.last
          options = nil unless options&.hash_type?

          if_not_exists = options&.children&.find do |pair|
            pair.children.first == IF_NOT_EXISTS
          end
          value = if_not_exists&.children&.last&.type
          if @disable_ddl_transaction && value != :true # rubocop:disable Lint/BooleanSymbol
            add_offense(node,
                        message: "Non-transactional migrations should be idempotent; add `if_not_exists: true`",
                        severity: :error)
          end
        end

        def check_remove_foreign_key(node, args)
          options = args.last
          options = nil unless options.hash_type?

          if_not_exists = options&.children&.find do |pair|
            pair.children.first == IF_EXISTS
          end
          value = if_not_exists&.children&.last&.type
          if @disable_ddl_transaction && value != :true # rubocop:disable Lint/BooleanSymbol
            add_offense(node,
                        message: "Non-transactional migrations should be idempotent; add `if_exists: true`",
                        severity: :error)
          end
        end
      end
    end
  end
end
