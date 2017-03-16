module RuboCop
  module Cop
    module Specs
      class NoSeleniumWebDriverWait < Cop
        MSG = "Avoid using Selenium::WebDriver::Wait.\n" \
              "Our finders (f/fj and ff/ffj) will wait up to the implicit wait" \
              " (just like find_element, etc), and will raise a" \
              " Selenium::WebDriver::Error::NoSuchElementError" \
              " (just like find_element, etc).\n" \
              "Look through custom_selenium_rspec_matchers.rb" \
              " and custom_wait_methods.rb.".freeze

        BAD_CONST = "Selenium::WebDriver::Wait".freeze
        BAD_CONST_MATCHER = BAD_CONST.split("::")
          .map { |name| ":#{name})" }
          .join(" ")

        # (const
        #   (const
        #     (const nil :Selenium) :WebDriver) :Wait)
        def_node_matcher :bad_const?, <<-PATTERN
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
