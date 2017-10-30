#
# Copyright (C) 2016 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

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
                (const ... #{BAD_CONST_MATCHER}
        PATTERN

        def on_const(node)
          return unless bad_const?(node)
          add_offense node, message: MSG, severity: :warning
        end
      end
    end
  end
end
