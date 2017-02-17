module RuboCop
  module Cop
    module Specs
      class ScopeHelperModules < Cop
        MSG = "Define all helper and factory methods within modules"\
              " (or `shared_context`). Otherwise they will live on Object"\
              " and potentially wreak havoc on other specs."

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
          add_offense node, :expression, MSG, :warning
        end

        private

        def top_level_def?(node)
          return false unless node.def_type?
          return false if node.ancestors.any? do |ancestor|
            ancestor.module_type? || ancestor.class_type? ||
              ancestor.type == :block &&
                WHITELISTED_BLOCKS.include?(ancestor.method_name)
          end
          true
        end
      end
    end
  end
end
