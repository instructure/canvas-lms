module RuboCop
  module Cop
    module Lint
      class NoFileUtilsRmRf < Cop
        MSG = "In order to enable spec parallelization, avoid FileUtils.rm_rf"\
              " and making persistent files/directories. Instead use"\
              " Dir.mktmpdir. See https://gerrit.instructure.com/#/c/73834"\
              " for the pattern you should follow."

        METHOD = :rm_rf
        RECEIVER = :FileUtils

        def on_send(node)
          receiver, method_name, *_args = *node
          return unless method_name == METHOD
          return unless receiver.children[1] == RECEIVER

          add_offense node, :expression, MSG
        end
      end
    end
  end
end
