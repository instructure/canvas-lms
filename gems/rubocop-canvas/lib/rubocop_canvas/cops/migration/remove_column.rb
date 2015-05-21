module RuboCop
  module Cop
    module Migration
      class RemoveColumn < Cop
        include RuboCop::Canvas::MigrationTags

        def on_def(node)
          method_name, *_args = *node
          @current_def = method_name
        end

        def on_defs(node)
          _receiver, method_name, *_args = *node
          @current_def = method_name
        end

        def on_send(node)
          super
          _receiver, method_name, *_args = *node
          if remove_column_in_predeploy?(method_name)
            message = "`remove_column` needs to be in a postdeploy migration"
            add_offense(node, :expression, message)
          end
        end

        private
        def remove_column_in_predeploy?(method_name)
          tags.include?(:predeploy) &&
            method_name == :remove_column &&
            @current_def == :up
        end
      end
    end
  end
end
