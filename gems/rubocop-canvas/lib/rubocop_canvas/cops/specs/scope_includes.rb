# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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
      class ScopeIncludes < Cop
        MSG = "Never `include` a module at the top-level. Otherwise its " \
              "methods will be added to `Object` (and thus everything), " \
              "causing all sorts of mayhem. Move this inside a `describe`, " \
              "`shared_context`, etc."

        WHITELISTED_BLOCKS = %i[
          class_eval
          context
          describe
          shared_context
          shared_examples
          shared_examples_for
          new
        ].freeze

        def on_send(node)
          receiver, method_name, *_args = *node
          return unless receiver.nil?
          return unless method_name == :include
          return if whitelisted_ancestor?(node)

          add_offense node, message: MSG, severity: :error
        end

        private

        def whitelisted_ancestor?(node)
          node.ancestors.any? do |ancestor|
            ancestor.module_type? ||
              ancestor.class_type? ||
              ancestor.def_type? ||
              (ancestor.block_type? &&
                WHITELISTED_BLOCKS.include?(ancestor.method_name))
          end
        end
      end
    end
  end
end
