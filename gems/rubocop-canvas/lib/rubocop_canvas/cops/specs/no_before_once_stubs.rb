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
      class NoBeforeOnceStubs < Cop
        MSG = "Stubs in a `before(:once)` block won't carry over"\
              " to the examples; you should move this to a `before(:each)`"

        # http://gofreerange.com/mocha/docs/Mocha/Mock.html
        # - stubs
        # - returns
        # homegrown:
        # - stub_file_data
        # - stub_kaltura
        # - stub_png_data
        STUB_METHODS = %i[
          stubs
          returns
          stub_file_data
          stub_kaltura
          stub_png_data
        ].freeze

        BLOCK_METHOD = :before
        BLOCK_ARG = :once

        def on_send(node)
          _receiver, method_name, *_args = *node
          return unless STUB_METHODS.include? method_name
          return unless node.ancestors.find do |ancestor|
            child = ancestor.children && ancestor.children[0]
            child &&
              child.is_a?(::RuboCop::AST::Node) &&
              child.to_a[1] == BLOCK_METHOD &&
              child.to_a[2] &&
              child.to_a[2].is_a?(::RuboCop::AST::Node) &&
              child.to_a[2].children[0] == BLOCK_ARG
          end
          add_offense node, message: MSG, severity: :warning
        end
      end
    end
  end
end
