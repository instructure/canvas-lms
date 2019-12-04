#
# Copyright (C) 2019 - present Instructure, Inc.
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

require_relative '../common'

module CopyToTrayPage

  # ------------------------------ Selectors -----------------------------

  # ------------------------------ Elements ------------------------------

  def copy_to_dialog
    f("[role='dialog']")
  end

  def course_search_dropdown
    main_span = fj("span label:contains('Select a Course')")
    main_span.find_element(:css, "input[role='combobox']")
  end

  def module_search_dropdown
    main_span = fj("span label:contains('Select a Module (optional)')")
    main_span.find_element(:css, "input[role='combobox']")
  end

  def course_dropdown_list
    f("ul[role='listbox']")
  end

  def course_dropdown_item(course_name)
    fj("li:contains(#{course_name})")
  end

  def module_dropdown_item(module_name)
    fj("li:contains(#{module_name})")
  end

  def copy_button
    fj("button:contains('Copy')")
  end

  def starting_copy_operation_alert
    f("[role=alert]")
  end

  def module_dropdown_list
    f("ul[role='listbox']")
  end

  # ------------------------------ Actions --------------------------------

end