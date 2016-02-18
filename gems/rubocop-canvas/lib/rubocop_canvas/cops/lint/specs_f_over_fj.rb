module RuboCop
  module Cop
    module Lint
      class SpecsFOverFj < Cop
        include RuboCop::Cop::Consts::JQuerySelectors

        SUSPECT_METHOD_NAMES = [:fj, :ffj]

        def on_send(node)
          _receiver, method_name, *args = *node
          return unless SUSPECT_METHOD_NAMES.include?(method_name)
          return if jquery_necessary?(args.to_a.first.children.first)
          add_offense node, :expression, error_msg(method_name)
        end

        private

        def jquery_necessary?(selector)
          # TODO: inspect the value of the variable
          return true unless selector.is_a?(String)
          selector =~ JQUERY_SELECTORS_REGEX
        end

        def error_msg(method)
          without_j = method.to_s.chomp("j")
          "Prefer `#{without_j}` instead of `#{method}`; `#{method}` should only be used if you are doing jquery-fake-css selectors (e.g. `:visible`). Unlike `#{without_j}`, `#{method}` will not wait for the element to appear in the DOM, often contributing to flickering failures."
        end
      end
    end
  end
end
