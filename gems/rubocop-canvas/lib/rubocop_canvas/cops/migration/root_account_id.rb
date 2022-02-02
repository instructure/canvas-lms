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
      class RootAccountId < Cop
        include RuboCop::Canvas::CurrentDef

        EXAMPLE_REFERENCES_LINE = "t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false"
        EXAMPLE_REPLICA_IDENTITY_LINE = %(add_replica_identity "%s", :root_account_id)

        def_node_matcher :create_table_block, <<~PATTERN
          (block (send nil? :create_table $_) ...)
        PATTERN

        def_node_search :root_account_id_column, <<~PATTERN
          (send lvar {:integer | :bigint | :column} (sym :root_account_id) ...)
        PATTERN

        def_node_search :t_call, <<~PATTERN
          (send lvar ...)
        PATTERN

        def_node_search :root_account_reference, <<~PATTERN
          (send lvar :references (sym :root_account) ...)
        PATTERN

        def_node_search :foreign_key_value, <<~PATTERN
          (pair (sym :foreign_key) $_)
        PATTERN

        def_node_search :to_table_accounts?, <<~PATTERN
          (pair (sym :to_table) (sym :accounts))
        PATTERN

        def_node_search :index_arg, <<~PATTERN
          (pair (sym :index) $_)
        PATTERN

        def_node_search :null_arg, <<~PATTERN
          (pair (sym :null) $_)
        PATTERN

        def_node_matcher :false?, <<~PATTERN
          (false)
        PATTERN

        def_node_search :add_replica_identity_search, <<~PATTERN
          (send nil? :add_replica_identity (str $_) (sym :root_account_id) ...)
        PATTERN

        def last_line_range(node)
          last_newline_pos = node.source.rindex("\n")
          return node.source_range unless last_newline_pos

          node.source_range.adjust(begin_pos: node.source.index(/\S/, last_newline_pos))
        end

        # since cops don't run in rails and don't have access to rails inflections
        # we will just kind of fake the mapping from model name to table name
        def on_def(node)
          super
          @replica_identity_models = add_replica_identity_search(node).map { |n| n.split("::").last.downcase }
        end

        def replica_identity_present?(table_name)
          table_name = table_name.value.to_s.delete("_")
          @replica_identity_models.any? { |model_name| table_name.include?(model_name) }
        end

        def on_block(node)
          return if @current_def == :down

          if (table_name = create_table_block(node))
            if (subnode = root_account_id_column(node).first)
              add_offense subnode, message: <<~TEXT
                Use `t.references` instead
                e.g. `#{EXAMPLE_REFERENCES_LINE}`
              TEXT
            elsif (subnode = root_account_reference(node).first)
              fk_node = foreign_key_value(subnode).first
              if !fk_node || !to_table_accounts?(fk_node)
                add_offense fk_node || subnode, message: <<~TEXT, severity: :warning
                  Use `foreign_key: { to_table: :accounts }`
                  e.g. `#{EXAMPLE_REFERENCES_LINE}`
                TEXT
              else
                null_node = null_arg(subnode).first
                if !null_node || !false?(null_node)
                  add_offense null_node || subnode, message: <<~TEXT, severity: :warning
                    Use `null: false`
                    e.g. `#{EXAMPLE_REFERENCES_LINE}`
                  TEXT
                else
                  iv_node = index_arg(subnode).first
                  if !iv_node || !false?(iv_node)
                    add_offense iv_node || subnode, message: <<~TEXT
                      Use `index: false` (the replica identity index should suffice)
                      e.g. `#{EXAMPLE_REFERENCES_LINE}`
                    TEXT
                  end
                end
              end
            else
              missing_ref = true
            end

            unless replica_identity_present?(table_name)
              # put the complaint on the last line of the block
              add_offense nil, location: last_line_range(node), message: <<~TEXT, severity: :warning
                Use `add_replica_identity` after the create_table block
                e.g. `#{EXAMPLE_REPLICA_IDENTITY_LINE % table_name.value.to_s.split("_").map(&:capitalize).join.sub(/s$/, "")}`
              TEXT
            end

            if missing_ref
              add_offense node, message: <<~TEXT, severity: :warning
                New tables need a root_account reference
                e.g. `#{EXAMPLE_REFERENCES_LINE}`
              TEXT
            end
          end
        end
      end
    end
  end
end
