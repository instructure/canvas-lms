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
      class Predeploy < Cop
        include RuboCop::Canvas::MigrationTags
        include RuboCop::Canvas::CurrentDef

        TABLE_MSG = "Create tables in a predeploy migration"
        COLUMN_MSG = "Add columns in a predeploy migration"
        INDEX_MSG = "Add indexes in a predeploy migration"

        CTB_ADD_COLUMN_METHODS = %i[column timestamps references string text integer float decimal datetime timestamp time date binary bool boolean].freeze

        def_node_matcher :create_table?, <<~PATTERN
          (send nil? :create_table ...)
        PATTERN

        def_node_matcher :add_column?, <<~PATTERN
          (send nil? :add_column ...)
        PATTERN

        def_node_matcher :add_reference?, <<~PATTERN
          (send nil? :add_reference ...)
        PATTERN

        def_node_matcher :add_index?, <<~PATTERN
          (send nil? :add_index ...)
        PATTERN

        def_node_matcher :change_table_block?, <<~PATTERN
          (block (send nil? :change_table ...) (args (arg $_)) ...)
        PATTERN

        def_node_search :change_table_method_calls, <<~PATTERN
          $(send lvar _ ...)
        PATTERN

        def_node_matcher :change_table_method_call, <<~PATTERN
          (send (lvar $_) $_ ...)
        PATTERN

        def on_block(node)
          return if @current_def == :down || @tags&.include?(:predeploy)

          if (arg = change_table_block?(node))
            change_table_method_calls(node).each do |subnode|
              call_arg, method = change_table_method_call(subnode)
              next unless call_arg == arg

              if CTB_ADD_COLUMN_METHODS.include?(method)
                add_offense subnode, message: COLUMN_MSG
              elsif method == :index
                add_offense subnode, message: INDEX_MSG
              end
            end
          end
        end

        def on_send(node)
          super
          return if @current_def == :down || @tags&.include?(:predeploy)

          if create_table?(node)
            add_offense node, message: TABLE_MSG
          elsif add_column?(node) || add_reference?(node)
            add_offense node, message: COLUMN_MSG
          elsif add_index?(node)
            add_offense node, message: INDEX_MSG
          end
        end
      end
    end
  end
end
