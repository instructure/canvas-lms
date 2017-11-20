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
    module Lint
      class FreezeConstants < Cop
        def on_casgn(node)
          _scope, _const_name, value = *node
          check_for_unfrozen_structures(value)
        end

        def check_for_unfrozen_structures(node, safe_at_this_level=false)
          return if node.nil?
          return if node.children.last == :to_i
          safe_at_next_level = false
          if node.type == :send
            safe_at_next_level = send_is_safe?(node)
          elsif node.type == :array || node.type == :hash
            mark_offense!(node) unless safe_at_this_level
          end
          return if node.type == :block
          check_children(node, safe_at_next_level)
        end

        private
        def send_is_safe?(node)
          return true if target_isnt_structure_or_string(node)
          return true if node.children.include?(:freeze)
          mark_offense!(node)
          false
        end

        def target_isnt_structure_or_string(node)
          target = node.children.first
          ![:hash, :array, :string].include?(target.type)
        end

        def check_children(node, safe_at_next_level)
          node.children.each do |child|
            if child.respond_to?(:type)
              check_for_unfrozen_structures(child, safe_at_next_level)
            end
          end
        end

        def mark_offense!(node)
          add_offense(node,
            message: "data structure constants should be frozen",
            severity: :warning)
        end

      end
    end
  end
end
