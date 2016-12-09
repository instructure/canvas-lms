module RuboCop
  module Cop
    module Specs
      class NoStrftime < Cop
        # include RuboCop::Cop::FileMeta
        MSG = "Avoid using strftime." \
              " Use format_date_for_view or format_time_for_view instead."

        METHOD = :strftime

        def on_send(node)
          _receiver, method_name, *_args = *node
          return unless method_name == METHOD

          add_offense node, :expression, MSG, :warning
        end
      end
    end
  end
end
