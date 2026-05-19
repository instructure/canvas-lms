# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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
      class WorkflowStateEnum < Base
        include RuboCop::Canvas::CurrentDef

        MSG = "workflow_state columns need an accompanying check constraint " \
              "(e.g. `t.check_constraint \"workflow_state IN ('active', 'deleted')\", " \
              'name: "chk_workflow_state_enum"`)'

        RESTRICT_ON_SEND = %i[add_column].freeze

        def_node_matcher :table_block?, <<~PATTERN
          (block (send nil? {:create_table | :change_table} ...) ...)
        PATTERN

        def_node_search :workflow_state_column_in_block, <<~PATTERN
          (send lvar :string (sym :workflow_state) ...)
        PATTERN

        def_node_search :check_constraints_in_block, <<~PATTERN
          (send lvar :check_constraint (str $_) ...)
        PATTERN

        def_node_matcher :standalone_workflow_state_column?, <<~PATTERN
          (send nil? :add_column _ (sym :workflow_state) (sym :string) ...)
        PATTERN

        def_node_search :standalone_check_constraints, <<~PATTERN
          (send nil? :add_check_constraint _ (str $_) ...)
        PATTERN

        def on_def(node)
          super
          @current_def_node = node
        end

        def on_defs(node)
          super
          @current_def_node = node
        end

        def on_block(node)
          return if @current_def == :down
          return unless table_block?(node)

          ws_nodes = workflow_state_column_in_block(node).to_a
          return if ws_nodes.empty?

          has_constraint = check_constraints_in_block(node).any? { |sql| sql.include?("workflow_state") }
          return if has_constraint

          ws_nodes.each { |n| add_offense(n, message: MSG, severity: :warning) }
        end

        def on_send(node)
          return if @current_def == :down
          return unless standalone_workflow_state_column?(node)
          return unless @current_def_node

          has_constraint = standalone_check_constraints(@current_def_node).any? { |sql| sql.include?("workflow_state") }
          return if has_constraint

          add_offense(node, message: MSG, severity: :warning)
        end
      end
    end
  end
end
