module RuboCop
  module Cop
    module Migration
      class ConcurrentIndex < Cop
        def on_send(node)
          _receiver, method_name, *args = *node

          case method_name
          when :disable_ddl_transaction!
            @disable_ddl_transaction = true
          when :add_index
            check_add_index(node, args)
          end
        end

        ALGORITHM = AST::Node.new(:sym, [:algorithm])

        def check_add_index(node, args)
          options = args.last
          return unless options.hash_type?

          algorithm = options.children.find do |pair|
            pair.children.first == ALGORITHM
          end
          return unless algorithm
          algorithm_name = algorithm.children.last.children.first

          add_offenses(node, algorithm_name)
        end

        private

        def add_offenses(node, algorithm_name)
          if algorithm_name != :concurrently
            add_offense(node, :expression, "Unknown algorithm name"\
                          " `#{algorithm_name}`, did you mean `:concurrently`?")
          end

          if algorithm_name == :concurrently && !@disable_ddl_transaction
            add_offense(node, :expression, "Concurrent index adds require"\
                                                 " `disable_ddl_transaction!`")
          end
        end
      end
    end
  end
end
