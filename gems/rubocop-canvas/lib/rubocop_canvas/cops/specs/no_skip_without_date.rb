# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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
#

module RuboCop
  module Cop
    module Specs
      # This cop checks that RSpec's `skip`
      # includes a date in the comment.
      #
      # @example
      #   # bad
      #   skip 'This test needs to be fixed'
      #   context "name", skip: "reason"
      #
      #   # good
      #   skip '2025-09-05 This test needs to be fixed'
      #   context "name", skip: "2025-09-05 reason"
      class NoSkipWithoutDate < RuboCop::Cop::Base
        MSG = "Must include a date for all 'skip' in the format YYYY-MM-DD."
        METHOD = :skip
        DATE_REGEX = /\d{4}-\d{2}-\d{2}/

        # Determines if a `skip` node is conditional.
        # Conditional skips are not required to have date.
        def on_if(node)
          @conditional_sends ||= []
          @conditional_sends.concat(node.children.select do |child_node|
            child_node.is_a?(RuboCop::AST::SendNode) && child_node.method_name == METHOD
          end)
        end

        def on_send(node)
          return if @conditional_sends&.include?(node)

          _receiver, method_name, *args = *node
          return unless method_name == METHOD

          # First arg should be a reason, if not present return
          # and let RSpec/PendingWithoutReason handle it.
          return unless args.to_a.first

          reason = args.to_a.first.children.first
          return if contains_date?(reason)

          # If no related comments contain the date format, add an offense.
          add_offense node, message: MSG, severity: :error
        end

        # Check for skip in RSpec metadata (e.g., context "name", skip: "reason")
        def on_hash(node)
          node.pairs.each do |pair|
            next unless pair.key.type == :sym && pair.key.value == :skip

            value_node = pair.value
            next unless value_node.type == :str

            skip_reason = value_node.value
            next if skip_reason.match?(DATE_REGEX)

            add_offense pair, message: MSG, severity: :error
          end
        end

        def contains_date?(reason)
          reason = reason.value if reason.is_a?(RuboCop::AST::StrNode)
          reason.match?(DATE_REGEX)
        end
      end
    end
  end
end
