module RuboCop
  module Cop
    module Migration
      class PrimaryKey < Cop
        def on_send(node)
          _receiver, method_name, *args = *node
          if method_name == :create_table
            check_create_table(node, args)
          end
        end

        NO_PK = Parser::CurrentRuby.parse("{ id: false }").children.first

        def check_create_table(node, args)
          options = args.last
          return unless options.hash_type?

          if options.children.find { |pair| pair == NO_PK }
            message = "Please always include a primary key"
            add_offense(node, :expression, message)
          end
        end
      end
    end
  end
end
