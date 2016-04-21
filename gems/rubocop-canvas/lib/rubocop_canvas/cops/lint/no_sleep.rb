module RuboCop
  module Cop
    module Lint
      class NoSleep < Cop
        include RuboCop::Cop::FileMeta

        CONTROLLER_MSG = "Avoid using sleep, as it will tie up this process."
        SPEC_MSG = "Avoid using sleep. Depending on what you are trying to do,"\
                   " you should instead consider: Timecop,"\
                   " vanilla `f` calls (since they wait),"\
                   " the `become` matcher, `wait_for_ajaximations`, or `keep_trying_until`."
        OTHER_MSG = "Avoid using sleep."

        METHOD = :sleep

        def on_send(node)
          _receiver, method_name, *_args = *node
          return unless method_name == METHOD

          if named_as_controller?
            add_offense node, :expression, CONTROLLER_MSG, :error
          elsif named_as_spec?
            add_offense node, :expression, SPEC_MSG
          else
            add_offense node, :expression, OTHER_MSG
          end
        end
      end
    end
  end
end
