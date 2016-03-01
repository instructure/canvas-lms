module RuboCop
  module Cop
    module Lint
      class SpecsHelperModules < Cop
        include RuboCop::Cop::FileMeta

        MSG = "Define all helper and factory methods within modules (or `shared_context`). Otherwise they will live on Object and potentially wreak havoc on other specs."
        SPEC_DIR_REGEX = /\/spec\//

        def on_def(node)
          return unless top_level_spec_def?(node)
          add_offense node, :expression, MSG
        end

        private

        def top_level_spec_def?(node)
          return false unless file_path =~ SPEC_DIR_REGEX
          return false unless node.def_type?
          return false if node.ancestors.any?(&:module_type?)
          true
        end
      end
    end
  end
end
