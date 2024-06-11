# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

class CoursePeople
  class << self
    include SeleniumDependencies

    def section_input
      f("#react_section_input input")
    end

    def loading_spinner
      f("#loading")
    end

    def section_input_search_result
      f('ul[role="listbox"] li')
    end

    def select_from_section_autocomplete(text)
      section_input.send_keys(text)
      wait_for_no_such_element(timeout: 3) { loading_spinner }
      section_input_search_result.click
      wait_for_ajaximations
    end
  end
end
