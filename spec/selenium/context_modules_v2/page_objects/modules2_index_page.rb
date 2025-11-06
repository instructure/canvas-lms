# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

module Modules2IndexPage
  #------------------------------ Selectors -----------------------------

  def assignments_due_button_selector
    "[data-testid='assignment-due-this-week-button']"
  end

  def collapse_all_modules_button_selector
    "button[aria-label='Collapse All Modules']"
  end

  def completion_requirement_selector
    "[data-testid='completion-requirement']"
  end

  def context_module_completion_requirement_selector(module_id)
    "#context_module_#{module_id} [data-testid='completion-requirement']"
  end

  def copy_to_button_selector
    "button:contains('Copy')"
  end

  def close_copy_tray_button_selector
    "[data-testid='confirm-action-secondary-button']"
  end

  def copy_to_tray_course_select_selector
    "#direct-share-course-select"
  end

  def course_option_selector(option_list_id, course_name)
    "#{option_list_options_selector(option_list_id)}:contains(#{course_name})"
  end

  def edit_item_modal_selector
    "[data-testid='edit-item-modal']"
  end

  def edit_item_submit_button_selector
    "form[data-testid='edit-item-modal'] button[type='submit']"
  end

  def edit_item_modal_title_selector
    "form[data-testid='edit-item-modal'] input[data-testid='edit-modal-title']"
  end

  def edit_item_modal_new_tab_checkbox_selector
    "form[data-testid='edit-item-modal'] input[data-testid='edit-modal-new-tab']"
  end

  def expand_all_modules_button_selector
    "button[aria-label='Expand All Modules']"
  end

  def empty_state_module_creation_button_selector
    "//button[.//span[text()='Create a new Module']]"
  end

  def clear_due_date_button_selector
    "[data-testid='due_at_clear_button']"
  end

  def get_student_views_assignment(course_id, assignment_id)
    get "/courses/#{course_id}/assignments/#{assignment_id}"
  end

  def manage_module_item_button_selector(module_item_id)
    "[data-testid='module-item-action-menu_#{module_item_id}']"
  end

  def manage_module_item_container_selector(module_item_id)
    "#context_module_item_#{module_item_id}"
  end

  def missing_assignment_button_selector
    "[data-testid='missing-assignment-button']"
  end

  def module_action_menu_selector(module_id)
    "[data-testid='module-action-menu_#{module_id}']"
  end

  def module_action_menu_deletetion_selector(module_id)
    "[data-testid='module-action-menu_#{module_id}-deletion']"
  end

  def module_action_menu_copy_selector(module_id)
    "[data-testid='module-action-menu_#{module_id}-copy']"
  end

  def module_page_dropdowns_selector
    "input[role='combobox'][title='All Modules']"
  end

  def module_file_drop_selector(module_id)
    "[data-module-id='#{module_id}'] [data-testid='module-file-drop']"
  end

  def module_header_expand_toggle_selector
    "[data-testid='module-header-expand-toggle']"
  end

  def module_header_due_date_selector(module_id)
    "#{module_header_selector(module_id)} [data-testid='friendly-date-time']"
  end

  def module_header_complete_all_pill_selector(module_id)
    "#{module_header_selector(module_id)} [data-testid='module-completion-requirement']"
  end

  def module_header_locked_icon_selector(module_id)
    "#{module_header_selector(module_id)} [data-testid='module-header-status-icon-lock']"
  end

  def module_header_missing_pill_selector(module_id)
    "#{module_header_selector(module_id)} [data-testid='module-header-missing-count']"
  end

  def module_header_prerequisites_selector(module_id)
    "#{module_header_selector(module_id)} [data-testid='module-header-prerequisites']"
  end

  def module_header_will_unlock_selector(module_id)
    "#{module_header_selector(module_id)} [data-testid='module-unlock-at-date']"
  end

  def module_header_selector(module_id)
    "#context_module_#{module_id}"
  end

  def module_item_action_menu_link_selector(tool_text)
    "//button[.//span[text()='#{tool_text}']]"
  end

  def module_item_action_menu_selector
    "[data-testid='module-item-action-menu']"
  end

  def module_item_assignment_icon_selector(module_item_id)
    "#{module_item_by_id_selector(module_item_id)} [data-testid='assignment-icon']"
  end

  def module_item_by_id_selector(module_item_id)
    "[data-item-id='#{module_item_id}']"
  end

  def module_item_title_by_id_selector(module_item_id)
    "[data-testid='module-item-title-link'][data-module-item-id='#{module_item_id}']"
  end

  def module_item_discussion_icon_selector(module_item_id)
    "#{module_item_by_id_selector(module_item_id)} [data-testid='discussion-icon']"
  end

  def module_item_due_date_selector(module_item_id)
    "#context_module_item_#{module_item_id} [data-testid='due-date']"
  end

  def module_item_header_selector(module_item_id)
    "#{module_item_by_id_selector(module_item_id)} [data-testid='subheader-title-text']"
  end

  def module_item_multiple_due_date_selector(module_item_id)
    "#context_module_item_#{module_item_id}  a:contains('Multiple Due Dates')"
  end

  def module_item_text_header_icon_selector(module_item_id)
    "#{module_item_by_id_selector(module_item_id)} [data-testid='document-icon']"
  end

  def module_item_indent_selector(module_item_id)
    "[data-item-id='#{module_item_id}'] div[style*='padding']"
  end

  def module_item_page_icon_selector(module_item_id)
    "#{module_item_by_id_selector(module_item_id)} [data-testid='page-icon']"
  end

  def module_item_publish_button_selector(module_item_id)
    "[data-testid='module-item-publish-button-#{module_item_id}']"
  end

  def module_item_quiz_icon_selector(module_item_id)
    "#{module_item_by_id_selector(module_item_id)} [data-testid='quiz-icon']"
  end

  def module_item_attachment_icon_selector(module_item_id)
    "#{module_item_by_id_selector(module_item_id)} [data-testid='attachment-icon']"
  end

  def module_item_status_icon_selector(module_item_id)
    "#{module_item_by_id_selector(module_item_id)} [data-testid='module-item-status-icon']"
  end

  def module_item_title_selector
    "[data-testid='module-item-title']"
  end

  def module_item_title_link_selector
    "[data-testid='module-item-title-link']"
  end

  def module_item_url_icon_selector(module_item_id)
    "#{module_item_by_id_selector(module_item_id)} [data-testid='url-icon']"
  end

  def blueprint_lock_button_selector(locked: false)
    locked ? '[data-testid="blueprint-lock-button"][aria-pressed="true"]' : '[data-testid="blueprint-lock-button"][aria-pressed="false"]'
  end

  def module_blueprint_lock_button_selector(module_item_id, locked: false)
    "#{module_item_by_id_selector(module_item_id)} #{blueprint_lock_button_selector(locked:)}"
  end

  def blueprint_lock_icon_selector(locked: false)
    locked ? 'svg[name="IconBlueprintLock"]' : 'svg[name="IconBlueprint"]'
  end

  def module_blueprint_lock_icon_selector(module_item_id, locked: false)
    "#{module_item_by_id_selector(module_item_id)} #{blueprint_lock_icon_selector(locked:)}"
  end

  def module_prerequisite_selector
    "[data-testid='module-header-prerequisites']"
  end

  def module_progression_status_bar_selector(module_id)
    "#{module_header_selector(module_id)} [data-testid='module-progression-status-bar']"
  end

  def module_progression_info_selector(module_id)
    "#{module_header_selector(module_id)} progress"
  end

  def module_publish_menu_selector
    "[data-testid='module-publish-menu']"
  end

  def module_publish_menu_for_module_selector(module_id)
    "#{module_header_selector(module_id)} #{module_publish_menu_selector}"
  end

  def module_publish_menu_spinner_selector
    "#{module_publish_menu_selector} [data-testid='publish-icon-spinner']"
  end

  def module_publish_with_all_items_selector
    "[data-testid='module-publish-with-all-items']"
  end

  def module_publish_selector
    "[data-testid='module-publish']"
  end

  def module_unpublish_with_all_items_selector
    "[data-testid='module-unpublish-with-all-items']"
  end

  def module_unpublish_selector
    "[data-testid='module-unpublish']"
  end

  def modules_publish_modal_selector
    "[data-testid='context-modules-publish-modal']"
  end

  def option_list_options_selector(option_list_id)
    "##{option_list_id} [role='option']"
  end

  def page_body
    f("body")
  end

  def progress_button_selector
    "#context-modules-header-view-progress-button"
  end

  def publish_all_continue_button_selector
    "#publish_all_continue_button"
  end

  def publish_modules_only_continue_button_selector
    "#publish_module_only_continue_button"
  end

  def unpublish_all_continue_button_selector
    "#unpublish_all_continue_button"
  end

  def publish_all_menu_selector
    "#context-modules-publish-menu button"
  end

  def publish_all_modules_and_items_selector
    "#publish_all_menu_item"
  end

  def publish_modules_only_selector
    "#publish_module_only_menu_item"
  end

  def unpublish_all_modules_and_items_selector
    "#unpublish_all_menu_item"
  end

  def unpublish_modules_only_selector
    "#unpublish_module_only_menu_item"
  end

  def pagination_container_selector
    '[data-testid="pagination-container"]'
  end

  def pagination_info_text_selector
    "#{pagination_container_selector} [data-testid='pagination-info-text']"
  end

  def pagination_page_buttons_selector
    "#{pagination_container_selector} button"
  end

  def pagination_page_current_page_button_selector
    "#{pagination_container_selector} button[aria-current='page']"
  end

  def send_to_modal_input_selector
    "#content-share-user-search"
  end

  def send_to_modal_modal_selector
    "[data-testid='send-to-item-modal']"
  end

  def student_modules_container_selector
    "[data-testid='modules-rewrite-student-container']"
  end

  def teacher_modules_container_selector
    "[data-testid='modules-rewrite-container']"
  end

  def context_module_selector(module_id)
    "[data-module-id='#{module_id}']"
  end

  def context_module_name_selector(module_name)
    "[data-module-name='#{module_name}']"
  end

  def context_module_item_selector(module_item_id)
    "#context_module_item_#{module_item_id}"
  end

  def bulk_publish_button_selector
    "[data-testid='context-modules-publish-menu']"
  end

  def context_module_item_published_icon_selector(module_item_id)
    "#{context_module_item_selector(module_item_id)} svg[name='IconPublish']"
  end

  def context_module_item_unpublished_icon_selector(module_item_id)
    "#{context_module_item_selector(module_item_id)} svg[name='IconUnpublished']"
  end

  def context_module_item_todo_selector(module_item_id, todo_text)
    "#{context_module_item_selector(module_item_id)} span:contains('#{todo_text}')"
  end

  def context_module_published_icon_selector(module_id)
    "#{context_module_selector(module_id)} svg[name='IconPublish']"
  end

  def context_module_unpublished_icon_selector(module_id)
    "#{context_module_selector(module_id)} svg[name='IconUnpublished']"
  end

  def context_module_expand_toggle_selector(module_id)
    "#{context_module_selector(module_id)} [data-testid='module-header-expand-toggle'][aria-expanded='false']"
  end

  def context_module_collapse_toggle_selector(module_id)
    "#{context_module_selector(module_id)} [data-testid='module-header-expand-toggle'][aria-expanded='true']"
  end

  def context_module_prerequisites_selector(module_id)
    "#{context_module_selector(module_id)} [data-testid='module-header-prerequisites']"
  end

  def context_module_view_assign_to_link_selector(module_id)
    "#{context_module_selector(module_id)} button:contains('View Assign To')"
  end

  def view_assign_to_link_selector
    "button:contains('View Assign To')"
  end

  def move_item_tray_selector
    "[data-testid='manage-module-content-tray']"
  end

  def external_tool_page_name_input_selector
    "[data-testid='external_item_page_name']"
  end

  def tab_create_item_selector
    "#tab-create-item-form"
  end

  def create_learning_object_name_input_selector
    "[data-testid='create-learning-object-name-input']"
  end

  def new_quiz_icon_selector
    "[data-testid='new-quiz-icon']"
  end

  def classic_quiz_icon_selector
    "[data-testid='quiz-icon']"
  end

  def text_header_input_selector
    "[placeholder='Enter header text']"
  end

  def url_input_selector
    "[placeholder='https://example.com']"
  end

  def url_title_input_selector
    "[placeholder='Enter page name']"
  end

  def visible_modules_header_selector
    "div[class*='context_module'] h2"
  end

  def quiz_engine_option_selector
    "[data-testid='create-item-quiz-engine-select']"
  end
  #------------------------------ Elements ------------------------------

  def completion_requirement
    f(completion_requirement_selector)
  end

  def context_module(module_id)
    f(context_module_selector(module_id))
  end

  def context_module_completion_requirement(module_id)
    f(context_module_completion_requirement_selector(module_id))
  end

  def context_module_name(module_name)
    ff(context_module_name_selector(module_name))
  end

  def context_module_expand_toggle(module_id)
    f(context_module_expand_toggle_selector(module_id))
  end

  def context_module_collapse_toggle(module_id)
    f(context_module_collapse_toggle_selector(module_id))
  end

  def assignments_due_button
    f(assignments_due_button_selector)
  end

  def collapse_all_modules_button
    f(collapse_all_modules_button_selector)
  end

  def empty_state_module_creation_button
    fxpath(empty_state_module_creation_button_selector)
  end

  def clear_due_date_button
    f(clear_due_date_button_selector)
  end

  def copy_button
    fj(copy_to_button_selector)
  end

  def close_copy_to_tray_button
    fj(close_copy_tray_button_selector)
  end

  def copy_to_tray_course_select
    f(copy_to_tray_course_select_selector)
  end

  def edit_item_modal
    f(edit_item_modal_selector)
  end

  def edit_item_modal_title_input_value
    edit_item_modal.find_element(:id, "title").attribute("value")
  end

  def edit_item_modal_url_value
    edit_item_modal.find_element(:css, "input[data-testid='edit-modal-url']").attribute("value")
  end

  def edit_item_modal_submit_button
    f(edit_item_submit_button_selector)
  end

  def edit_item_modal_title_input
    f(edit_item_modal_title_selector)
  end

  def edit_item_modal_new_tab_checkbox
    f(edit_item_modal_new_tab_checkbox_selector)
  end

  def expand_all_modules_button
    f(expand_all_modules_button_selector)
  end

  def manage_module_item_button(module_item_id)
    f(manage_module_item_button_selector(module_item_id))
  end

  def manage_module_item_container(module_item_id)
    f(manage_module_item_container_selector(module_item_id))
  end

  def missing_assignment_button
    f(missing_assignment_button_selector)
  end

  def module_action_menu(module_id)
    f(module_action_menu_selector(module_id))
  end

  def module_action_menu_deletetion(module_id)
    f(module_action_menu_deletetion_selector(module_id))
  end

  def module_action_menu_copy(module_id)
    f(module_action_menu_copy_selector(module_id))
  end

  def module_page_student_dropdown
    ff(module_page_dropdowns_selector)[1]
  end

  def module_page_teacher_dropdown
    ff(module_page_dropdowns_selector)[0]
  end

  def module_file_drop_element(module_id)
    f(module_file_drop_selector(module_id))
  end

  def module_file_drop_element_exists?(module_id)
    element_exists?(module_file_drop_selector(module_id))
  end

  def module_header_complete_all_pill(module_id)
    f(module_header_complete_all_pill_selector(module_id))
  end

  def module_header_due_date(module_id)
    f(module_header_due_date_selector(module_id))
  end

  def module_header_expand_toggles
    ff(module_header_expand_toggle_selector)
  end

  def module_header_locked_icon(module_id)
    f(module_header_locked_icon_selector(module_id))
  end

  def module_header_missing_pill(module_id)
    f(module_header_missing_pill_selector(module_id))
  end

  def module_header_prerequisites(module_id)
    f(module_header_prerequisites_selector(module_id))
  end

  def module_header_will_unlock_label(module_id)
    f(module_header_will_unlock_selector(module_id))
  end

  def module_item_action_menu
    f(module_item_action_menu_selector)
  end

  def module_item_action_menu_link(tool_text)
    fxpath(module_item_action_menu_link_selector(tool_text))
  end

  def module_item_assignment_icon(module_item_id)
    f(module_item_assignment_icon_selector(module_item_id))
  end

  def module_item_by_id(module_item_id)
    f(module_item_by_id_selector(module_item_id))
  end

  def module_item_title_by_id(module_item_id)
    f(module_item_title_by_id_selector(module_item_id))
  end

  def module_item_discussion_icon(module_item_id)
    f(module_item_discussion_icon_selector(module_item_id))
  end

  def module_item_due_date(module_item_id)
    f(module_item_due_date_selector(module_item_id))
  end

  def module_item_header(module_item_id)
    f(module_item_header_selector(module_item_id))
  end

  def module_item_indent(module_item_id)
    f(module_item_indent_selector(module_item_id))[:style]
  end

  def module_item_mission_pill(module_item_id)
    f(module_item_mission_pill_selector(module_item_id))
  end

  def module_item_multiple_due_dates(module_item_id)
    fj(module_item_multiple_due_date_selector(module_item_id))
  end

  def module_item_page_icon(module_item_id)
    f(module_item_page_icon_selector(module_item_id))
  end

  def module_item_publish_button(module_item_id)
    f(module_item_publish_button_selector(module_item_id))
  end

  def module_item_quiz_icon(module_item_id)
    f(module_item_quiz_icon_selector(module_item_id))
  end

  def module_item_attachment_icon(module_item_id)
    f(module_item_attachment_icon_selector(module_item_id))
  end

  def module_item_text_header_icon(module_item_id)
    f(module_item_text_header_icon_selector(module_item_id))
  end

  def module_item_status_icon(module_item_id)
    f(module_item_status_icon_selector(module_item_id))
  end

  def module_item_titles
    ff(module_item_title_selector)
  end

  def context_module_item_todo(module_item_id, todo_text)
    fj(context_module_item_todo_selector(module_item_id, todo_text))
  end

  def module_item_title_links
    ff(module_item_title_link_selector)
  end

  def context_module_prerequisites(module_id)
    f(context_module_prerequisites_selector(module_id))
  end

  def module_item_url_icon(module_item_id)
    f(module_item_url_icon_selector(module_item_id))
  end

  def modules_publish_modal
    f(modules_publish_modal_selector)
  end

  def module_blueprint_lock_icon(module_item_id, locked: false)
    f(module_blueprint_lock_icon_selector(module_item_id, locked:))
  end

  def module_blueprint_lock_button(module_item_id, locked: false)
    f(module_blueprint_lock_button_selector(module_item_id, locked:))
  end

  def module_prerequisite
    f(module_prerequisite_selector)
  end

  def module_progression_info(module_id)
    f(module_progression_info_selector(module_id))
  end

  def module_progression_status_bar(module_id)
    f(module_progression_status_bar_selector(module_id))
  end

  def option_list(option_list_id)
    ff(option_list_options_selector(option_list_id))
  end

  def option_list_course_option(option_list_id, course_name)
    fj(course_option_selector(option_list_id, course_name))
  end

  def progress_button
    f(progress_button_selector)
  end

  def publish_all_continue_button
    f(publish_all_continue_button_selector)
  end

  def publish_module_only_continue_button
    f(publish_modules_only_continue_button_selector)
  end

  def unpublish_all_continue_button
    f(unpublish_all_continue_button_selector)
  end

  def publish_all_menu
    f(publish_all_menu_selector)
  end

  def publish_all_modules_and_items
    f(publish_all_modules_and_items_selector)
  end

  def publish_modules_only
    f(publish_modules_only_selector)
  end

  def unpublish_all_modules_and_items
    f(unpublish_all_modules_and_items_selector)
  end

  def unpublish_modules_only
    f(unpublish_modules_only_selector)
  end

  def module_publish_menu_buttons
    ff(module_publish_menu_selector)
  end

  def module_publish_menu_for(module_id)
    f(module_publish_menu_for_module_selector(module_id))
  end

  def module_publish_menu_button_spinners
    ff(module_publish_menu_spinner_selector)
  end

  def module_publish_with_all_items
    f(module_publish_with_all_items_selector)
  end

  def module_publish
    f(module_publish_selector)
  end

  def module_unpublish_with_all_items
    f(module_unpublish_with_all_items_selector)
  end

  def module_unpublish
    f(module_unpublish_selector)
  end

  def module_pagination_container(module_id)
    f("#{context_module_selector(module_id)} #{pagination_container_selector}")
  end

  def module_pagination_buttons(module_id)
    ff("#{context_module_selector(module_id)} #{pagination_page_buttons_selector}")
  end

  def pagination_info_text
    f(pagination_info_text_selector).text
  end

  def pagination_page_buttons
    ff(pagination_page_buttons_selector)
  end

  def pagination_page_current_page_button
    f(pagination_page_current_page_button_selector)
  end

  def send_to_form_selected_elements
    ff("button[type='button']", send_to_modal_input_container)
  end

  def send_to_modal
    f(send_to_modal_modal_selector)
  end

  def send_to_modal_input
    f(send_to_modal_input_selector)
  end

  def send_to_modal_input_container
    fxpath("../..", send_to_modal_input)
  end

  def student_modules_container
    f(student_modules_container_selector)
  end

  def teacher_modules_container
    f(teacher_modules_container_selector)
  end

  def text_header_input
    f(text_header_input_selector)
  end

  def url_input
    f(url_input_selector)
  end

  def url_title_input
    f(url_title_input_selector)
  end

  def screenreader_alert
    f("#flash_screenreader_holder")
  end

  def move_item_tray_select_modules_listbox
    f("[data-testid='select_module_listbox']")
  end

  def move_item_tray_place_contents_listbox
    f("[data-testid='select_position_listbox']")
  end

  def move_item_tray_select_page_listbox
    f("[id^='Select_'][data-testid='select_module_listbox'][title*='Page']")
  end

  def page_option(page_number)
    fj("[role='option']:contains('Page #{page_number}')")
  end

  def reference_item_option(title)
    fj("[role='option']:contains('#{title}')")
  end

  def move_item_tray_reference_listbox
    fxpath("//label[span[text()='Select Reference Item']]//input[@role='combobox']")
  end

  def tab_create_item
    f(tab_create_item_selector)
  end

  def create_learning_object_name_input
    f(create_learning_object_name_input_selector)
  end

  def new_quiz_icon
    ff(new_quiz_icon_selector)
  end

  def classic_quiz_icon
    ff(classic_quiz_icon_selector)
  end

  def visible_module_headers
    ff(visible_modules_header_selector)
  end

  def view_assign_to_links
    ffj(view_assign_to_link_selector)
  end

  def view_assign_to_link_on_module(module_id)
    fj(context_module_view_assign_to_link_selector(module_id))
  end

  def quiz_engine_option_exists?
    element_exists?(quiz_engine_option_selector)
  end

  def all_modules
    ff('[data-rbd-droppable-id="modules-list"] [data-module-id]')
  end

  #------------------------------ Actions -------------------------------

  def list_all_module_ids
    @module_ids = all_modules.map { |module_element| module_element.attribute("data-module-id") }
  end

  def assignments_due_button_exists?
    element_exists?(assignments_due_button_selector)
  end

  def click_assignments_due_button
    assignments_due_button.click
  end

  def click_manage_module_item_assign_to
    module_item_action_menu_link("Assign To...").click
  end

  def course_modules_setup(student_view: false)
    student_view ? set_rewrite_student_flag : set_rewrite_flag
    @quiz = @course.quizzes.create!(title: "some quiz")
    @quiz.publish!
    @quiz2 = @course.quizzes.create!(title: "some quiz 2")
    @quiz2.publish!
    @assignment = @course.assignments.create!(title: "assignment 1", submission_types: "online_text_entry")
    @assignment2 = @course.assignments.create!(title: "assignment 2",
                                               submission_types: "online_text_entry",
                                               points_possible: 10)
    @assignment3 = @course.assignments.create!(title: "assignment 3", submission_types: "online_text_entry")
    @assignment4 = @course.assignments.create!(title: "assignment 4", submission_types: "online_text_entry")
    @discussion = @course.discussion_topics.create!(title: "Discussion title", message: "Testing")
    @wiki_page = @course.wiki_pages.create!(title: "Wiki", body: "Testing")

    @module1 = @course.context_modules.create!(name: "module1")
    @module2 = @course.context_modules.create!(name: "module2")
    @module3 = @course.context_modules.create!(name: "module3")
    @module_item1 = @module1.add_item({ id: @assignment.id, type: "assignment" })
    @module_item2 = @module1.add_item({ id: @assignment2.id, type: "assignment" })
    @module_item3 = @module2.add_item({ id: @assignment3.id, type: "assignment" })
    @module_item4 = @module2.add_item({ id: @quiz.id, type: "quiz" })

    @module_item5 = @module3.add_item({ id: @quiz2.id, type: "quiz" })
    @module_item6 = @module3.add_item({ id: @assignment4.id, type: "assignment" })
    @module_item7 = @module3.add_item({ id: @discussion.id, type: "discussion_topic" })
    @module_item8 = @module3.add_item({ id: @wiki_page.id, type: "page" })

    @course.reload
  end

  def missing_assignment_button_exists?
    element_exists?(missing_assignment_button_selector)
  end

  def module_header_due_date_exists?(module_id)
    element_exists?(module_header_due_date_selector(module_id))
  end

  def modules2_student_setup
    course_with_student(active_all: true)
    course_modules_setup(student_view: true)
  end

  def modules2_teacher_setup
    course_with_teacher(active_all: true)
    course_modules_setup
  end

  def module_progression_info_text(module_id)
    element_value_for_attr(module_progression_info(module_id), "aria-valuetext")
  end

  def pagination_info_text_includes?(text)
    pagination_info_text.include?(text)
  end

  def set_rewrite_flag(rewrite_status: true)
    rewrite_status ? @course.root_account.enable_feature!(:modules_page_rewrite) : @course.root_account.disable_feature!(:modules_page_rewrite)
  end

  def set_rewrite_student_flag(rewrite_status: true)
    rewrite_status ? @course.root_account.enable_feature!(:modules_page_rewrite_student_view) : @course.root_account.disable_feature!(:modules_page_rewrite_student_view)
  end

  def visit_course(course)
    get "/courses/#{course.id}"
  end

  def add_item_button(module_id)
    fj("button:contains('Add Item')", context_module_selector(module_id))
  end

  def add_item_button_selector
    "[data-testid='add-item-button']"
  end

  def new_item_type_select_selector
    "[data-testid='add-item-type-selector']"
  end

  def add_existing_item_select_selector
    "[data-testid='add-item-content-select']"
  end

  def search_and_select_existing_item(item_name)
    search_chars = (item_name.length > 10) ? item_name[0..3] : item_name[0..1]
    wait_for_ajaximations
    wait_for(method: nil, timeout: 10) { f(add_existing_item_select_selector) }
    input_element = f(add_existing_item_select_selector)
    input_element.click
    input_element.send_keys(search_chars)
    wait_for_ajaximations
    wait_for(method: nil, timeout: 5) { fj("[role='option']:contains('#{item_name}')") }
    fj("[role='option']:contains('#{item_name}')").click
  end

  def add_item_modal_add_item_button
    fj("button:contains('Add Item')", f("[data-testid='add-item-modal']"))
  end

  # This method only works for simple items right now like Assignment, Quiz, Page, etc.
  # It does not work for External Tool or File since those require additional steps
  # after selecting the item type from the dropdown
  def add_newly_created_item(item_type, cxt_module, item_title_text = nil)
    add_item_button(cxt_module.id).click
    wait_for_ajaximations

    # Select from the dropdown
    click_INSTUI_Select_option(new_item_type_select_selector, item_type)
    wait_for_ajaximations

    tab_create_item.click

    # Fill in the quiz details
    new_item_name = (item_title_text || ("New" + item_type)).to_s

    replace_content(create_learning_object_name_input, new_item_name)

    yield if block_given?

    # Click Add Item
    add_item_modal_add_item_button.click
    wait_for_ajaximations
  end

  def add_existing_learning_object(item_type, cxt_module, item_title_text)
    add_item_button(cxt_module.id).click
    wait_for_ajaximations

    # Select from the dropdown
    click_INSTUI_Select_option(new_item_type_select_selector, item_type)
    wait_for_ajaximations

    search_and_select_existing_item(item_title_text)
    add_item_modal_add_item_button.click
    wait_for_ajaximations
  end

  def expand_all_modules
    expand_all_modules_button.click
    wait_for_ajaximations
  end

  def modules_published_icon_state?(published: true, modules: nil)
    (modules || @course.context_modules).all? do |context_module|
      if published
        f(context_module_published_icon_selector(context_module.id))
      else
        f(context_module_unpublished_icon_selector(context_module.id))
      end
    end
  end

  def module_items_published_icon_state?(published: true, modules: nil)
    (modules || @course.context_modules).all? do |context_module|
      context_module.content_tags.all? do |content_tag|
        if published
          f(context_module_item_published_icon_selector(content_tag.id))
        else
          f(context_module_item_unpublished_icon_selector(content_tag.id))
        end
      end
    end
  end

  def wait_until_bulk_publish_action_finished
    wait = Selenium::WebDriver::Wait.new(timeout: 5)

    wait.until { !element_exists?(modules_publish_modal_selector) }
  end

  def external_tool_page_name_input
    f(external_tool_page_name_input_selector)
  end

  # method to scroll to the top of the modules page, especially for the canvas for elementary pages that
  # have a collapsing head that hides content.
  def scroll_to_the_top_of_modules_page
    where_to_scroll = element_exists?("#student-view-btn") ? "#student-view-btn" : "#easy_student_view"
    scroll_to(f(where_to_scroll))
    wait_for_ajaximations
  end

  def module_item_action_menu_link_exists?(tool_text)
    element_exists?(module_item_action_menu_link_selector(tool_text), true)
  end

  def input_text_in_text_header_input(text)
    replace_content(text_header_input, text)
  end

  def input_text_in_url_input(text)
    replace_content(url_input, text)
  end

  def input_text_in_url_title_input(text)
    replace_content(url_title_input, text)
  end

  def scroll_to_module(module_id)
    scroll_to(f("[data-testid='module-action-menu_#{module_id}']"))
  end

  def open_move_item_tray(moved_item_id, target_module_name)
    manage_module_item_button(moved_item_id).click
    module_item_action_menu_link("Move to...").click

    # select destination module
    move_item_tray_select_modules_listbox.click
    option_list_id = move_item_tray_select_modules_listbox.attribute("aria-controls")
    option_list_course_option(option_list_id, target_module_name).click

    # open the "Place ..." dropdown
    move_item_tray_place_contents_listbox.click
  end
end
