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

module ModulesIndexPage
  #------------------------------ Selectors -----------------------------

  def all_collapsed_modules_selector
    ".context_module.collapsed_module:not(#context_module_blank)"
  end

  def all_expanded_modules_selector
    ".context_module:not(.collapsed_module):not(#context_module_blank)"
  end

  def expand_collapse_all_button_selector
    "#expand_collapse_all"
  end

  def collapse_module_link_selector(module_id)
    ".collapse_module_link[aria-controls='context_module_content_#{module_id}']"
  end

  def context_module_selector(module_id)
    "#context_module_#{module_id}"
  end

  def delete_card_button_selector
    "[data-testid = 'delete-card-button']"
  end

  def delete_module_item_button_selector(module_item)
    "#context_module_item_#{module_item.id} .delete_item_link"
  end

  def expand_module_link_selector(module_id)
    ".expand_module_link[aria-controls='context_module_content_#{module_id}']"
  end

  def manage_module_item_assign_to_selector(module_item_id)
    "#context_module_item_#{module_item_id} .module-item-assign-to-link"
  end

  def module_item_copy_to_selector(module_item_id)
    "#context_module_item_#{module_item_id} .module_item_copy_to"
  end

  def module_item_copy_to_tray_selector
    "[role='dialog'][aria-label='Copy To...']"
  end

  def module_item_drag_handle_selector(module_item_id)
    "##{module_item_id} .move_item_link"
  end

  def manage_module_item_indent_selector(module_item_id)
    "#context_module_item_#{module_item_id} .indent_item_link"
  end

  def module_create_button_selector
    "//button[.//*[contains(text(), 'Create a new Module')]]"
  end

  def module_content_selector(module_id)
    "#context_module_content_#{module_id}"
  end

  def module_items_selector(module_id)
    "#context_module_content_#{module_id} .context_module_item"
  end

  def module_item_selector(module_item_id)
    "#context_module_item_#{module_item_id}"
  end

  def module_item_duplicate_selector(module_item_id)
    "#context_module_item_#{module_item_id} .duplicate_item_link"
  end

  def module_item_move_selector(module_item_id)
    "#context_module_item_#{module_item_id} .move_module_item_link"
  end

  def module_item_send_to_selector(module_item_id)
    "#context_module_item_#{module_item_id} .module_item_send_to"
  end

  def module_item_move_tray_selector
    "[role='dialog'][aria-label='Move Module Item']"
  end

  def module_item_move_tray_module_selector
    ".move-select-form"
  end

  def module_move_contents_tray_module_selector
    ".move-select-form"
  end

  def module_item_move_tray_location_selector
    "[data-testid='select-position']"
  end

  def module_move_contents_tray_place_selector
    "[data-testid='select-position']"
  end

  def module_item_move_tray_sibling_selector
    "[data-testid='select-sibling']"
  end

  def module_move_contents_tray_sibling_selector
    "[data-testid='select-sibling']"
  end

  def module_item_move_tray_move_button_selector
    "#move-item-tray-submit-button"
  end

  def module_item_page_button_selector(module_id, button_text)
    "//*[@id = 'context_module_#{module_id}']//button[.//*[contains(text(), '#{button_text}')]]"
  end

  def module_move_contents_selector(module_id)
    "#context_module_#{module_id} .move_module_contents_link"
  end

  def new_module_link_selector
    ".add_module_link"
  end

  def no_context_modules_message_selector
    "#no_context_modules_message"
  end

  def pagination_selector(module_id)
    "[data-testid='module-#{module_id}-pagination']"
  end

  def pill_message_selector(module_id)
    "#context_module_#{module_id} .requirements_message li"
  end

  def require_sequential_progress_selector(module_id)
    "#context_module_#{module_id} .module_header_items .require_sequential_progress"
  end

  def send_to_dialog_selector
    "[role='dialog'][aria-label='Send To...']"
  end

  def unlock_details_selector(module_id)
    "#context_module_content_#{module_id} .unlock_details"
  end

  def module_publish_button_selector(module_id)
    "#context_module_#{module_id} div.module-publish-icon button"
  end

  def publish_module_and_items_option_selector
    "button:contains('Publish module and all items')"
  end

  def unpublish_module_and_items_option_selector
    "button:contains('Unpublish module and all items')"
  end

  def published_module_icon_selector(module_id)
    "#context_module_#{module_id} .module_header_items svg[name='IconPublish']"
  end

  def unpublished_module_icon_selector(module_id)
    "#context_module_#{module_id} .module_header_items svg[name='IconUnpublished']"
  end

  def all_modules_selector
    "#context_modules .context_module:not(#context_module_blank)"
  end

  def duplicate_module_button_selector(context_module)
    "#context_module_#{context_module.id} a.duplicate_module_link"
  end

  def module_index_menu_tool_link_selector(tool_text)
    "[role=menuitem]:contains('#{tool_text}')"
  end

  def view_assign_to_link_selector
    ".view_assign_link"
  end

  def show_all_or_less_button_selector
    ".show-all-or-less-button"
  end

  def show_all_button_selector(context_module)
    "#context_module_#{context_module.id} .show-all-or-less-button.show-all"
  end

  def show_less_button_selector(context_module)
    "#context_module_#{context_module.id} .show-all-or-less-button.show-less"
  end

  def module_file_drop_selector
    "[data-testid='module-file-drop']"
  end

  #------------------------------ Elements ------------------------------

  def expand_collapse_all_button
    f(expand_collapse_all_button_selector)
  end

  def collapse_module_link(module_id)
    f(collapse_module_link_selector(module_id))
  end

  def context_module(module_id)
    f(context_module_selector(module_id))
  end

  def all_context_modules
    ff(".context_module:not(#context_module_blank)")
  end

  def collapsed_module(module_id)
    f("#context_module_#{module_id}.collapsed_module")
  end

  def all_collapsed_modules
    ff(all_collapsed_modules_selector)
  rescue
    []
  end

  def all_expanded_modules
    ff(all_expanded_modules_selector)
  rescue
    []
  end

  def delete_card_button
    ff(delete_card_button_selector)
  end

  def expand_module_link(module_id)
    f(expand_module_link_selector(module_id))
  end

  def manage_module_item_assign_to(module_item_id)
    f(manage_module_item_assign_to_selector(module_item_id))
  end

  def manage_module_item_indent(module_item_id)
    f(manage_module_item_indent_selector(module_item_id))
  end

  def modules_index_settings_button
    fj("[role=button]:contains('Modules Settings')")
  end

  def module_index_menu_tool_link(tool_text)
    fj(module_index_menu_tool_link_selector(tool_text))
  end

  def module_item_copy_to(module_item_id)
    f(module_item_copy_to_selector(module_item_id))
  end

  def module_create_button
    fxpath(module_create_button_selector)
  end

  def module_content(module_id)
    f(module_content_selector(module_id))
  end

  def module_item(module_item_id)
    f(module_item_selector(module_item_id))
  end

  def module_item_page_button(module_id, button_text)
    fxpath(module_item_page_button_selector(module_id, button_text))
  end

  def module_item_drag_handle(module_item_id)
    f(module_item_drag_handle_selector(module_item_id))
  end

  def module_item_duplicate(module_item_id)
    f(module_item_duplicate_selector(module_item_id))
  end

  def module_item_move(module_item_id)
    f(module_item_move_selector(module_item_id))
  end

  def module_item_move_tray
    f(module_item_move_tray_selector)
  end

  def module_item_move_tray_module
    ff(module_item_move_tray_module_selector)[0]
  end

  def module_move_contents_tray_module
    ff(module_move_contents_tray_module_selector)[0]
  end

  def module_item_move_tray_module_location
    f(module_item_move_tray_location_selector)
  end

  def module_move_contents_tray_module_place
    f(module_move_contents_tray_place_selector)
  end

  def module_item_move_tray_sibling
    f(module_item_move_tray_sibling_selector)
  end

  def module_item_move_tray_move_button
    f(module_item_move_tray_move_button_selector)
  end

  def module_item_name_selector(course_id, module_number)
    "//a[@title='#{course_id}:#{module_number}']"
  end

  def module_item_send_to(module_item_id)
    f(module_item_send_to_selector(module_item_id))
  end

  def module_move_contents(module_id)
    f(module_move_contents_selector(module_id))
  end

  def module_move_contents_tray_sibling
    f(module_move_contents_tray_sibling_selector)
  end

  def module_row(module_id)
    f("#context_module_#{module_id}")
  end

  def module_settings_menu(module_id)
    module_row(module_id).find_element(:css, "ul[role='menu']")
  end

  def module_index_settings_menu
    f(".module_index_tools ul[role=menu]")
  end

  def new_module_link
    f(new_module_link_selector)
  end

  def no_context_modules_message
    f(no_context_modules_message_selector)
  end

  def pagination(module_id)
    f(pagination_selector(module_id))
  end

  def pill_message(module_id)
    f(pill_message_selector(module_id))
  end

  def require_sequential_progress(module_id)
    f(require_sequential_progress_selector(module_id))
  end

  def tool_dialog
    f("div[role='dialog']")
  end

  def tool_dialog_header
    f("div[role='dialog'] h2")
  end

  def tool_dialog_iframe
    f(".tool_launch")
  end

  def view_assign
    ff(".view_assign")
  end

  def manage_module_button(context_module)
    f("#context_module_#{context_module.id} .module_header_items button[aria-label='Manage #{context_module.name}']")
  end

  def manage_module_item_button(module_item)
    f("#context_module_item_#{module_item.id} .al-trigger")
  end

  def add_module_item_button(context_module)
    f("#context_module_#{context_module.id} .add_module_item_link")
  end

  def delete_module_item_button(module_item)
    f(delete_module_item_button_selector(module_item))
  end

  def duplicate_module_button(context_module)
    f(duplicate_module_button_selector(context_module))
  end

  def unlock_details(module_id)
    f(unlock_details_selector(module_id))
  end

  def module_publish_button(module_id)
    f(module_publish_button_selector(module_id))
  end

  def publish_module_and_items_option
    fj(publish_module_and_items_option_selector)
  end

  def unpublish_module_and_items_option
    fj(unpublish_module_and_items_option_selector)
  end

  def published_module_icon(module_id)
    f(published_module_icon_selector(module_id))
  end

  def unpublished_module_icon(module_id)
    f(unpublished_module_icon_selector(module_id))
  end

  def all_modules
    ff(all_modules_selector)
  end

  def show_all_button(context_module)
    f(show_all_button_selector(context_module))
  end

  def show_less_button(context_module)
    f(show_less_button_selector(context_module))
  end

  #------------------------------ Actions ------------------------------
  def visit_modules_index_page(course_id)
    get "/courses/#{course_id}/modules"
  end

  def add_new_module_item(context_module, type, name)
    add_module_item_button(context_module).click
    f("#add_module_item_select").click
    f("#add_module_item_select option[value=\"#{type}\"]").click
    f("##{type}s_select option[value=\"new\"]").click
    replace_content(f("##{type}s_select input.item_title"), name)
    fj(".add_item_button:visible").click
    wait_for_ajax_requests
  end

  def big_course_setup
    course_modules = create_modules(3, true)
    course_assignments = create_assignments([@course.id], 70)

    51.times do |i|
      course_modules[0].add_item({ type: "Assignment", id: course_assignments[i] }, nil, position: i + 1)
      course_modules[0].save!
    end

    10.times do |i|
      course_modules[1].add_item({ type: "Assignment", id: course_assignments[i + 51] }, nil, position: i + 1)
      course_modules[1].save!
    end

    9.times do |i|
      course_modules[2].add_item({ type: "Assignment", id: course_assignments[i + 61] }, nil, position: i + 1)
      course_modules[2].save!
    end

    course_modules
  end

  def click_delete_card_button(button_number)
    delete_card_button[button_number].click
  end

  def click_manage_module_button(context_module)
    manage_module_button(context_module).click
  end

  def click_manage_module_item_assign_to(module_item)
    manage_module_item_assign_to(module_item.id).click
  end

  def click_module_item_page_button(module_id, button_text)
    module_item_page_button(module_id, button_text).click
  end

  def click_module_item_copy_to(module_item)
    module_item_copy_to(module_item.id).click
  end

  def click_module_item_duplicate(module_item)
    module_item_duplicate(module_item.id).click
  end

  def click_module_item_move(module_item)
    module_item_move(module_item.id).click
  end

  def click_module_item_move_tray_move_button
    module_item_move_tray_move_button.click
  end

  def click_module_item_send_to(module_item)
    module_item_send_to(module_item.id).click
  end

  def click_manage_module_item_indent(module_item)
    manage_module_item_indent(module_item.id).click
  end

  def click_module_create_button
    module_create_button.click
  end

  def click_module_move_contents(module_id)
    module_move_contents(module_id).click
  end

  def click_new_module_link
    new_module_link.click
  end

  def copy_to_tray_exists?
    element_exists?(module_item_copy_to_tray_selector)
  end

  def pagination_exists?(module_id)
    element_exists?(pagination_selector(module_id))
  end

  def module_content_style(module_id)
    element_value_for_attr(module_content(module_id), "style")
  end

  def module_item_exists?(course_id, module_item_id)
    element_exists?(module_item_name_selector(course_id, module_item_id), true)
  end

  def any_module_items?(module_id)
    element_exists?(module_items_selector(module_id))
  end

  def move_tray_exists?
    element_exists?(module_item_move_tray_selector)
  end

  def send_to_dialog_exists?
    element_exists?(send_to_dialog_selector)
  end

  def select_module_item_move_tray_module(module_name)
    click_option(module_item_move_tray_module, module_name)
  end

  def select_module_move_contents_tray_module(module_name)
    click_option(module_move_contents_tray_module, module_name)
  end

  def select_module_item_move_tray_location(location)
    click_option(module_item_move_tray_module_location, location)
  end

  def select_module_move_contents_tray_place(location)
    click_option(module_move_contents_tray_module_place, location)
  end

  def select_module_item_move_tray_sibling(sibling)
    click_option(module_item_move_tray_sibling, sibling)
  end

  def select_module_move_contents_tray_sibling(sibling)
    click_option(module_move_contents_tray_sibling, sibling)
  end

  def retrieve_assignment_content_tag(content_module, assignment)
    ContentTag.where(context_module_id: content_module.id, content_type: "Assignment", content_id: assignment.id)
  end

  # method to scroll to the top of the modules page, especially for the canvas for elementary pages that
  # have a collapsing head that hides content.
  def scroll_to_the_top_of_modules_page
    where_to_scroll = element_exists?("#student-view-btn") ? "#student-view-btn" : "#easy_student_view"
    scroll_to(f(where_to_scroll))
    wait_for_ajaximations
  end

  def scroll_to_module(module_name)
    scroll_to(f("[aria-label='Manage #{module_name}']"))
  end

  def publish_module_and_items(module_id)
    module_publish_button(module_id).click
    publish_module_and_items_option.click
    wait_for_ajax_requests
  end

  def unpublish_module_and_items(module_id)
    module_publish_button(module_id).click
    unpublish_module_and_items_option.click
    wait_for_ajax_requests
  end

  def click_on_edit_item_link(tag_id)
    f("#context_module_item_#{tag_id} .al-trigger").click
    fj(".edit_item_link:visible").click
  end

  def click_on_duplicate_item_link(tag_id)
    f("#context_module_item_#{tag_id} .al-trigger").click
    fj(".duplicate_item_link:visible").click
  end

  def check_estimated_duration_in_editor(exists, visible)
    expect(element_exists?(".ui-dialog")).to be_truthy
    if exists
      expect(element_exists?("#estimated_duration_edit")).to be_truthy
      if visible
        expect(f("#estimated_duration_edit")).to be_displayed
      else
        expect(f("#estimated_duration_edit")).not_to be_displayed
      end
    else
      expect(element_exists?("#estimated_duration_edit")).to be_falsey
    end
  end

  def close_editor_dialog
    fj(".ui-dialog-titlebar-close:visible").click
  end

  def drag_and_drop_module_item(module_item_selector1, module_item_selector2)
    js_drag_and_drop(module_item_selector1, module_item_selector2)
  end

  def save_edit_item_form
    form = f("#edit_item_form")
    form.submit
    wait_for_ajaximations
  end

  def duplicate_module(context_module)
    manage_module_button(context_module).click
    duplicate_module_button(context_module).click
    wait_for_ajax_requests
  end
end
