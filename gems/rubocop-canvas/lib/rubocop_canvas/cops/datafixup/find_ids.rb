module RuboCop
  module Cop
    module Datafixup
      class FindIds < Cop
        def on_class(node)
          @with_unscoped = (node.to_sexp =~ /with_exclusive_scope/) || (node.to_sexp =~ /unscoped/)
        end

        def on_send(node)
          _receiver, method_name, *_args = *node

          if method_name.to_s =~ /find_ids_in_/ && !@with_unscoped
            add_offense(node, :expression, "find_ids_in without "\
                            "'unscoped' might be dangerous", :warning)
          end
        end
      end
    end
  end
end
