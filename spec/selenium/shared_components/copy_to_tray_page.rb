# frozen_string_literal: true

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
  
  def copy_to_dialog_css_selector
    "[role='dialog'][aria-label='Copy To...']"
  end

  def import_dialog_css_selector
    "[role='dialog'][aria-label='Import...']"
  end

  # ------------------------------ Elements ------------------------------

  def copy_to_dialog
    f(copy_to_dialog_css_selector)
  end

  def import_dialog
    f(import_dialog_css_selector)
  end

  def course_search_dropdown
    main_span = fj("span label:contains('Select a Course')")
    main_span.find_element(:css, "input[role='combobox']")
  end

  def module_search_dropdown
    main_span = fj("span label:contains('Select a Module (optional)')")
    main_span.find_element(:css, "input[role='combobox']")
  end

  def dropdowns_in_tray
    ff("input[role='combobox']")
  end

  def course_dropdown_list
    ff("ul[role='listbox']")
  end

  def course_dropdown_item(course_name)
    fj("[role='option']:contains('#{course_name}')")
  end

  def module_dropdown_item(module_name)
    fj("[role='option']:contains('#{module_name}')")
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

  def placement_dropdown
    f("select[data-testid='select-position']")
  end

  def placement_dropdown_options
    placement_dropdown.find_all('option')
  end

  def import_button
    fj("button:contains('Import')")
  end

  def copy_dialog_import_success_alert
    copy_to_dialog.find_element(:css, "span[role='alert']")
  end

  def import_dialog_import_success_alert
    import_dialog.find_element(:css, "span[role='alert']")
  end
  # ------------------------------ Actions --------------------------------
  # the course dropdown triggers a fetch that needs to then fetch the modules

  def wait_for_module_search_dropdown
    wait_for(method: nil, timeout: 1) { dropdowns_in_tray.count == 2}
  end

end