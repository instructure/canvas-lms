module RuboCop
  module Cop
    module Lint
      class TimecopNoBlock < Cop
        MSG = "Using Timecop without a block is dangerous, as it may result in skewing time itself for other specs. Please use a block to contain your time travel."
        RECEIVER = :Timecop

        def on_send(node)
          receiver, _method_name, *_args = *node
          return unless receiver && receiver.children[1] == RECEIVER

          if node.parent &&
             node.parent.block_type? &&
             node.parent.children[0] &&
             node.parent.children[0].children[0] &&
             node.parent.children[0].children[0].children[1] == RECEIVER
            return
          end

          add_offense node, :expression, MSG
        end
      end
    end
  end
end
