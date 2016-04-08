module RuboCop
  module Cop
    module Lint
      class SpecsHelperModules < Cop
        include RuboCop::Cop::FileMeta

        MSG = "Define all helper and factory methods within modules (or `shared_context`). Otherwise they will live on Object and potentially wreak havoc on other specs."
        SPEC_DIR_REGEX = /\/spec\//
        WHITELISTED_BLOCKS = %i[context describe shared_context shared_examples]

        def on_def(node)
          return unless top_level_spec_def?(node)
          add_offense node, :expression, MSG
        end

        private

        def top_level_spec_def?(node)
          return false unless in_spec_dir?
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
