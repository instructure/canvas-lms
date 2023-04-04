# frozen_string_literal: true

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
    module Lint
      class NoSleep < Cop
        include RuboCop::Cop::FileMeta

        CONTROLLER_MSG = "Avoid using sleep, as it will tie up this process."
        SPEC_MSG = "Avoid using sleep. Depending on what you are trying to do, " \
                   "you should instead consider: Timecop, " \
                   "vanilla `f` calls (since they wait), " \
                   "the `become` matcher, `wait_for_ajaximations`, or `keep_trying_until`."
        OTHER_MSG = "Avoid using sleep."

        METHOD = :sleep

        def on_send(node)
          _receiver, method_name, *_args = *node
          return unless method_name == METHOD

          if named_as_controller?
            add_offense node, message: CONTROLLER_MSG, severity: :error
          elsif named_as_spec?
            add_offense node, message: SPEC_MSG, severity: :warning
          else
            add_offense node, message: OTHER_MSG, severity: :warning
          end
        end
      end
    end
  end
end
