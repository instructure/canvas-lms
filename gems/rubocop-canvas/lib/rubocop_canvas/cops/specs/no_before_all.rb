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
      class NoBeforeAll < Cop
        MSG = "Use `before(:once)` for efficient data setup, rather than"\
              " manually setting up and tearing down with `:all` hooks."\
              " Learn more here: https://discourse.instructure.com/t/speeding-up-specs-with-once-ler/87"

        BAD_METHOD = :before
        BAD_ARG = :all

        def on_send(node)
          _receiver, method_name, *args = *node
          return unless BAD_METHOD == method_name
          first_arg = args.to_a.first
          return unless first_arg
          return unless BAD_ARG == first_arg.children.first
          add_offense node, message: MSG, severity: :warning
        end
      end
    end
  end
end
