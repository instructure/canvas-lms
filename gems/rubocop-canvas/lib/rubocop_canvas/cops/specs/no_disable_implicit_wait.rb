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
      class NoDisableImplicitWait < Cop
        MSG = "Avoid using disable_implicit_wait.\n" \
              "Look through custom_selenium_rspec_matchers.rb" \
              " and custom_wait_methods.rb.".freeze

        METHOD = :disable_implicit_wait

        def on_send(node)
          _receiver, method_name, *_args = *node
          return unless method_name == METHOD
          add_offense node, message: MSG, severity: :warning
        end
      end
    end
  end
end
