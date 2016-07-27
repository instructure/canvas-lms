module RuboCop
  module Cop
    module Specs
      class NoExecuteScript < Cop
        MSG = "Avoid using execute_script. Instead, perform actual"\
              " user interactions such as click/keypress. If these"\
              " seem insufficient, consider converting your"\
              " integration spec into a JavaScript unit test."

        METHOD = :execute_script

        def on_send(node)
          _receiver, method_name, *_args = *node
          return unless method_name == METHOD
          add_offense node, :expression, MSG, :warning
        end
      end
    end
  end
end
