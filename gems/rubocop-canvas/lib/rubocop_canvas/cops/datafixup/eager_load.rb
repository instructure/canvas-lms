module RuboCop
  module Cop
    module Datafixup
      class EagerLoad < Cop
        def on_send(node)
          _receiver, method_name, *_args = *node
          if method_name.to_s == 'eager_load'
            add_offense(node,
              :expression,
              "eager_load in a data fixup causes errors",
              :error)
          end
        end
      end
    end
  end
end
