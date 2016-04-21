module RuboCop
  module Cop
    module Specs
      class NoBeforeAll < Cop
        MSG = "Use `before(:once)` for efficient data setup, rather than"\
              " manually setting up and tearing down with `:all` hooks."\
              " Learn more here: https://discourse.instructure.com/t/speeding-up-specs-with-once-ler/87"

        BAD_METHOD = :before
        BAD_ARG = :all

        def on_send(node)
          _receiver, method_name, *args = *node
          return unless BAD_METHOD == method_name
          first_arg = args.to_a.first
          return unless first_arg
          return unless BAD_ARG == first_arg.children.first
          add_offense node, :expression, MSG
        end
      end
    end
  end
end
