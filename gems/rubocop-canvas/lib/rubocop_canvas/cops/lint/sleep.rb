module RuboCop
  module Cop
    module Lint
      class Sleep < Cop
        include RuboCop::Cop::FileMeta

        CONTROLLER_MSG = "Avoid using sleep, as it will tie up this process."
        SPEC_MSG = "Avoid using sleep. Depending on what you are trying to do, you should instead consider: vanilla `f` calls (since they wait), the `become` matcher, `wait_for_ajaximations`, or `keep_trying_until`."
        MSG = "Avoid using sleep."
        METHOD = :sleep

        def on_send(node)
          _receiver, method_name, *args = *node
          return unless method_name == METHOD

          if named_as_controller?
            add_offense node, :expression, CONTROLLER_MSG, :error
          elsif named_as_spec?
            add_offense node, :expression, SPEC_MSG
          else
            add_offense node, :expression, MSG
          end
        end
      end
    end
  end
end
