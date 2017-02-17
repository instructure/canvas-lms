module RuboCop
  module Cop
    module Specs
      class NoNoSuchElementError < Cop
        MSG = "Avoid using Selenium::WebDriver::Error::NoSuchElementError.\n" \
              "Our finders (f/fj and ff/ffj) will wait up to the implicit wait" \
              " (just like find_element, etc), and will raise a" \
              " Selenium::WebDriver::Error::NoSuchElementError" \
              " (just like find_element, etc).\n" \
              "Look through custom_selenium_rspec_matchers.rb, particularly" \
              " contain_css and contain_jqcss."

        BAD_CONST = "Selenium::WebDriver::Error::NoSuchElementError"
        BAD_CONST_MATCHER = BAD_CONST.split("::")
                              .map { |name| ":#{name})" }
                              .join(" ")

        # (const
        #   (const
        #     (const
        #       (const nil :Selenium) :WebDriver) :Error) :NoSuchElementError)
        def_node_matcher :bad_const?, <<-PATTERN
          (const
            (const
              (const
                (const nil #{BAD_CONST_MATCHER}
        PATTERN

        def on_const(node)
          return unless bad_const?(node)
          add_offense node, :expression, MSG, :warning
        end
      end
    end
  end
end
