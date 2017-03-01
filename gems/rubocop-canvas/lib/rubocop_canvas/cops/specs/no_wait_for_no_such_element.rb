module RuboCop
  module Cop
    module Specs
      class NoWaitForNoSuchElement < Cop
        MSG = "Avoid using wait_for_no_such_element. Instead, use"\
              " not_to contain_css/contain_link.\n"\
              "e.g. expect(f('#courses')).not_to contain_css('#course_123')".freeze

        METHOD = :wait_for_no_such_element

        def on_send(node)
          _receiver, method_name, *_args = *node
          return unless method_name == METHOD
          add_offense node, :expression, MSG, :warning
        end
      end
    end
  end
end
