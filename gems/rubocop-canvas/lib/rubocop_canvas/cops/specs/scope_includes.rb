# frozen_string_literal: true
module RuboCop
  module Cop
    module Specs
      class ScopeIncludes < Cop
        MSG = "Never `include` a module at the top-level. Otherwise its "\
              "methods will be added to `Object` (and thus everything), "\
              "causing all sorts of mayhem. Move this inside a `describe`, "\
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

          add_offense node, :expression, MSG, :error
        end

        private

        def whitelisted_ancestor?(node)
          node.ancestors.any? do |ancestor|
            ancestor.module_type? ||
            ancestor.class_type? ||
            ancestor.def_type? ||
            ancestor.block_type? &&
              WHITELISTED_BLOCKS.include?(ancestor.method_name)
          end
        end
      end
    end
  end
end
