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
      class ScopeHelperModules < Cop
        MSG = "Define all helper and factory methods within modules " \
              "(or `shared_context`). Otherwise they will live on Object " \
              "and potentially wreak havoc on other specs."

        WHITELISTED_BLOCKS = %i[
          class_eval
          context
          describe
          shared_context
          shared_examples
          shared_examples_for
        ].freeze

        def on_def(node)
          return unless top_level_def?(node)

          add_offense node, message: MSG, severity: :warning
        end

        private

        def top_level_def?(node)
          return false unless node.def_type?
          return false if node.ancestors.any? do |ancestor|
            ancestor.module_type? || ancestor.class_type? ||
            (ancestor.type == :block &&
            WHITELISTED_BLOCKS.include?(ancestor.method_name))
          end

          true
        end
      end
    end
  end
end
