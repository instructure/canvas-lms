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
  def context_module_selector(module_id)
    "#context_module_#{module_id}"
  end

  def manage_module_item_assign_to_selector(module_item_id)
    "#context_module_item_#{module_item_id} .module-item-assign-to-link"
  end

  def manage_module_item_indent_selector(module_item_id)
    "#context_module_item_#{module_item_id} .indent_item_link"
  end

  def module_create_button_selector
    "//button[.//*[contains(text(), 'Create a new Module')]]"
  end

  def module_item_selector(module_item_id)
    "#context_module_item_#{module_item_id}"
  end

  def new_module_link_selector
    ".add_module_link"
  end

  def no_context_modules_message_selector
    "#no_context_modules_message"
  end

  def pill_message_selector(module_id)
    "#context_module_#{module_id} .requirements_message li"
  end

  def require_sequential_progress_selector(module_id)
    "#context_module_#{module_id} .module_header_items .require_sequential_progress"
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
    "#context_modules .context_module"
  end

  def duplicate_module_button_selector(context_module)
    "#context_module_#{context_module.id} a.duplicate_module_link"
  end

  #------------------------------ Elements ------------------------------
  def context_module(module_id)
    f(context_module_selector(module_id))
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
    fj("[role=menuitem]:contains('#{tool_text}')")
  end

  def module_create_button
    fxpath(module_create_button_selector)
  end

  def module_item(module_item_id)
    f(module_item_selector(module_item_id))
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

  def click_manage_module_item_assign_to(module_item)
    manage_module_item_assign_to(module_item.id).click
  end

  def click_manage_module_item_indent(module_item)
    manage_module_item_indent(module_item.id).click
  end

  def click_module_create_button
    module_create_button.click
  end

  def click_new_module_link
    new_module_link.click
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
end
