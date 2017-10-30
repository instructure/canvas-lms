#
# Copyright (C) 2017 - present Instructure, Inc.
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
      class NoWaitForNoSuchElement < Cop
        MSG = "Avoid using wait_for_no_such_element. Instead, use"\
              " not_to contain_css/contain_link.\n"\
              "e.g. expect(f('#courses')).not_to contain_css('#course_123')".freeze

        METHOD = :wait_for_no_such_element

        def on_send(node)
          _receiver, method_name, *_args = *node
          return unless method_name == METHOD
          add_offense node, message: MSG, severity: :warning
        end
      end
    end
  end
end
