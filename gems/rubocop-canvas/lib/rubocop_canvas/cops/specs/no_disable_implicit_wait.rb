module RuboCop
  module Cop
    module Specs
      class NoDisableImplicitWait < Cop
        MSG = "Avoid using disable_implicit_wait.\n" \
              "Look through custom_selenium_rspec_matchers.rb" \
              " and custom_wait_methods.rb.".freeze

        METHOD = :disable_implicit_wait

        def on_send(node)
          _receiver, method_name, *_args = *node
          return unless method_name == METHOD
          add_offense node, :expression, MSG, :warning
        end
      end
    end
  end
end
