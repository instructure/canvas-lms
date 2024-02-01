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
require_relative "../../common"

module AssignmentsIndexPage
  #------------------------------ Selectors -----------------------------

  def assignment_row_selector(assignment_id)
    "#assignment_#{assignment_id}"
  end
  #------------------------------ Elements ------------------------------

  def assignment_index_menu_tool_link(tool_text)
    fj("[role=menuitem]:contains('#{tool_text}')")
  end

  def assignments_rows
    f("#ag-list")
  end

  def assignment_row(assignment_id)
    f(assignment_row_selector(assignment_id))
  end

  def manage_assignment_menu(assignment_id)
    f("#assign_#{assignment_id}_manage_link")
  end

  def assign_to_menu_link(assignment_id)
    f("#assign_to_#{assignment_id}_link")
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
    f("div.item-group-container")
  end

  def manage_assignment_group_menu(assignment_group)
    f("#ag_#{assignment_group}_manage_link")
  end

  def assignment_group_menu_tool_link(assignment_group)
    f("#assignment_group_#{assignment_group} a.menu_tool_link")
  end

  def assignment_group_loading_spinner
    f("div.loadingIndicator")
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

  def bulk_edit_dates_menu_jqselector
    "li:contains('Edit Assignment Dates')"
  end

  def bulk_edit_dates_menu
    fj(bulk_edit_dates_menu_jqselector)
  end

  def assignment_groups_weight
    fj("li:contains('Assignment Groups Weight')")
  end

  def bulk_edit_root
    f("#bulkEditRoot")
  end

  def bulk_edit_tr_rows
    ff("#bulkEditRoot [role='table'] [role='row']")
  end

  def bulk_edit_loading_spinner
    fj("#bulkEditRoot:contains('Loading')")
  end

  def bulk_edit_assignment_row(assignment_name)
    fj("tr:contains('#{assignment_name}')")
  end

  def assignment_dates_inputs(assignment_name)
    ff("input[role='combobox']", bulk_edit_assignment_row(assignment_name))
  end

  def bulk_edit_save_button
    fj("button:contains('Save')", bulk_edit_root)
  end

  def saving_dates_button
    fj("button:contains('Saving...')")
  end

  def batch_edit_button
    fj("button:contains('Batch Edit')")
  end

  def select_assignment_checkbox(assignment_name)
    f("input[type='checkbox']", bulk_edit_assignment_row(assignment_name))
  end

  def batch_edit_dialog
    f("span [role='dialog']")
  end

  def batch_edit_dialog_ok_button
    fj("button:contains('Ok')")
  end

  def batch_edit_dialog_days_up_button
    ff("button", batch_edit_dialog)[1]
  end

  def batch_edit_dialog_days_down_button
    ff("button", batch_edit_dialog)[2]
  end

  def dialog_remove_date_radio_btn
    ff("input[type='radio']", batch_edit_dialog)[1]
  end

  def dialog_shift_date_radio_btn
    ff("input[type='radio']", batch_edit_dialog)[0]
  end

  def peer_review_requests(assignment_id)
    f("#assignment_student_peer_review_#{assignment_id}")
  end

  def assessment_request(index, assignment_name)
    f("a[aria-label='Required Peer Review #{index} for #{assignment_name}']")
  end

  #------------------------------ Actions --------------------------------

  def click_assign_to_menu_link(assignment_id)
    assign_to_menu_link(assignment_id).click
  end

  def click_assignment_settings_menu(assignment_id)
    assignment_settings_menu(assignment_id).click
  end

  def click_manage_assignment_button(assignment_id)
    manage_assignment_menu(assignment_id).click
  end

  def visit_assignments_index_page(course_id)
    get "/courses/#{course_id}/assignments"
    wait_for(method: nil, timeout: 1) { assignment_group_loading_spinner.displayed? == false }
  end

  def goto_bulk_edit_view
    course_assignments_settings_button.click
    bulk_edit_dates_menu.click
    wait_for(method: nil, timeout: 5) { bulk_edit_loading_spinner.displayed? == false }
  end

  def save_bulk_edited_dates
    bulk_edit_save_button.click
    run_jobs
    wait_for(method: nil, timeout: 5) { saving_dates_button.displayed? == false }
  end

  def open_batch_edit_dialog
    batch_edit_button.click
    wait_for(method: nil, timeout: 3) { batch_edit_dialog.displayed? == true }
  end
end
