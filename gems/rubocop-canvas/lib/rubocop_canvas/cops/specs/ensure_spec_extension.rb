# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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
    module Specs
      # most of this has been stolen from:
      # https://github.com/nevir/rubocop-rspec/blob/master/lib/rubocop/rspec/top_level_describe.rb
      # https://github.com/nevir/rubocop-rspec/blob/9aa33ee7014e8d6d580b12fe2651b32ccdaa7a92/lib/rubocop/cop/rspec/file_path.rb
      class EnsureSpecExtension < Cop
        include RuboCop::Cop::FileMeta

        MSG = "Spec files need to end with \"_spec.rb\" " \
              "for rspec  to find and run them."

        METHODS = [:context, :describe].freeze

        def on_send(node)
          return if named_as_spec?
          return unless top_level_describe?(node)

          add_offense node, message: MSG, severity: :warning
        end

        private

        def top_level_describe?(node)
          _receiver, method_name, *_args = *node
          return false unless METHODS.include?(method_name)

          top_level_nodes.include?(node)
        end

        def top_level_nodes
          nodes = describe_statement_children(root_node)
          # If we have no top level describe statements, we need to check any
          # blocks on the top level (e.g. after a require).
          if nodes.empty?
            nodes = node_children(root_node).map do |child|
              describe_statement_children(child) if child.type == :block
            end.flatten.compact
          end

          nodes
        end

        def describe_statement_children(node)
          node_children(node).select do |element|
            element.type == :send && METHODS.include?(element.children[1])
          end
        end

        def node_children(node)
          node.children.select { |e| e.is_a? Parser::AST::Node }
        end

        def root_node
          processed_source.ast
        end
      end
    end
  end
end
