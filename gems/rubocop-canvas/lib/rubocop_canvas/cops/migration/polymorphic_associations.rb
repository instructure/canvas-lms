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
      class PolymorphicAssociations < Base
        MSG = "`polymorphic:` must be an array of table names, e.g. `polymorphic: %i[account course]`"

        def on_send(node)
          return unless polymorphic_references_call?(node)

          pair = polymorphic_pair(node)
          return unless pair

          value = pair.value
          unless value.array_type?
            add_offense(pair, message: MSG)
            return
          end

          unless value.values.all?(&:sym_type?)
            add_offense(pair, message: MSG)
          end
        end

        private

        def polymorphic_pair(node)
          options = node.arguments.last
          return unless options&.hash_type?

          options.pairs.find { |p| p.key.value == :polymorphic }
        end

        # Match `add_reference` called on self (implicit or explicit),
        # or `t.references` inside a create_table/change_table block.
        def polymorphic_references_call?(node)
          return false unless node.send_type?

          if node.method?(:add_reference)
            receiver = node.receiver
            receiver.nil? || receiver.self_type?
          elsif node.method?(:references)
            table_block_variable?(node.receiver)
          else
            false
          end
        end

        # Check that the receiver is a block argument of a create_table
        # or change_table call (whose own receiver is self or implicit).
        def table_block_variable?(receiver)
          return false unless receiver&.lvar_type?

          block = receiver.parent
          block = block.parent while block && !block.block_type?
          return false unless block

          send_node = block.send_node
          return false unless %i[create_table change_table].include?(send_node.method_name)

          send_receiver = send_node.receiver
          send_receiver.nil? || send_receiver.self_type?
        end
      end
    end
  end
end
