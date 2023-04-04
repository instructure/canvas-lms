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
      class NoFileUtilsRmRf < Cop
        MSG = "In order to enable spec parallelization, avoid FileUtils.rm_rf " \
              "and making persistent files/directories. Instead use " \
              "Dir.mktmpdir. See https://gerrit.instructure.com/#/c/73834 " \
              "for the pattern you should follow."

        METHOD = :rm_rf
        RECEIVER = :FileUtils

        def on_send(node)
          receiver, method_name, *_args = *node
          return unless method_name == METHOD
          return unless receiver.children[1] == RECEIVER

          add_offense node, message: MSG, severity: :warning
        end
      end
    end
  end
end
