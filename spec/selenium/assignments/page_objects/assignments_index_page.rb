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
require_relative '../../common'

module AssignmentsIndexPage
  #------------------------------ Selectors -----------------------------

  #------------------------------ Elements ------------------------------

  def assignments_rows
    f('#ag-list')
  end

  def assignment_row(assignment_id)
    f("#assignment_#{assignment_id}")
  end

  def manage_assignment_menu(assignment_id)
    f("#assign_#{assignment_id}_manage_link")
  end

  def assignment_settings_menu(assignment_id)
    f("#assignment_#{assignment_id}_settings_list")
  end

  def copy_assignment_menu_link(assignment_id)
    f("#assignment_#{assignment_id}_settings_copy_to")
  end

  def send_assignment_menu_link(assignment_id)
    f("#assignment_#{assignment_id}_settings_share_user")
  end

  def assignment_groups_div
    f('div.item-group-container')
  end

  def manage_assignment_group_menu(assignment_group)
    f("#ag_#{assignment_group}_manage_link")
  end

  def assignment_group_menu_tool_link(assignment_group)
    f("#assignment_group_#{assignment_group} a.menu_tool_link")
  end

  def assignment_group_loading_spinner
    f('div.loadingIndicator')
  end

  def tool_dialog
    f("div[role='dialog']")
  end

  def tool_dialog_header
    f("div[role='dialog'] h2")
  end

  def tool_dialog_iframe
    tool_dialog.find_element(:css, "iframe")
  end

  def course_assignments_settings_button
    f("#course_assignment_settings_link")
  end

  def course_assignments_settings_menu_items
    ff("ul[role='menu'] li")
  end

  #------------------------------ Actions --------------------------------

  def visit_assignments_index_page(course_id)
    get "/courses/#{course_id}/assignments"
    wait_for(method: nil, timeout: 1) { assignment_group_loading_spinner.displayed? == false}
  end

end
