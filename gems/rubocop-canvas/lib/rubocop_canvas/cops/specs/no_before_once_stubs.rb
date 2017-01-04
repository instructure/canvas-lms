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
              child.is_a?(Node) &&
              child.to_a[1] == BLOCK_METHOD &&
              child.to_a[2] &&
              child.to_a[2].is_a?(Node) &&
              child.to_a[2].children[0] == BLOCK_ARG
          end
          add_offense node, :expression, MSG, :warning
        end
      end
    end
  end
end
