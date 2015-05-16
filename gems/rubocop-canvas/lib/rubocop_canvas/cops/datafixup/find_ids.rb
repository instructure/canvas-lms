module RuboCop
  module Cop
    module Datafixup
      class FindIds < Cop
        def on_class(node)
          @with_exclusive_scope = node.to_sexp =~ /with_exclusive_scope/
        end

        def on_send(node)
          _receiver, method_name, *_args = *node

          if method_name.to_s =~ /find_ids_in_/ && !@with_exclusive_scope
            add_offense(node, :expression, "find_ids_in without "\
                            "with_exclusive_scope might be dangerous", :warning)
          end
        end
      end
    end
  end
end
