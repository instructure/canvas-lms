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

  def copy_to_button_selector
    "button:contains('Copy')"
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

  def expand_all_modules_button_selector
    "button[aria-label='Expand All Modules']"
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

  def module_header_selector(module_id)
    "#context_module_#{module_id}"
  end

  def module_item_action_menu_link_selector(tool_text)
    "[role=menuitem]:contains('#{tool_text}')"
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

  def module_item_discussion_icon_selector(module_item_id)
    "#{module_item_by_id_selector(module_item_id)} [data-testid='discussion-icon']"
  end

  def module_item_header_selector(module_item_id)
    "#{module_item_by_id_selector(module_item_id)} [data-testid='subheader-titl-text']"
  end

  def module_item_indent_selector(module_item_id)
    "[data-item-id='#{module_item_id}'] div[style*='padding']"
  end

  def module_item_page_icon_selector(module_item_id)
    "#{module_item_by_id_selector(module_item_id)} [data-testid='page-icon']"
  end

  def module_item_quiz_icon_selector(module_item_id)
    "#{module_item_by_id_selector(module_item_id)} [data-testid='quiz-icon']"
  end

  def module_item_status_icon_selector(module_item_id)
    "#{module_item_by_id_selector(module_item_id)} [data-testid='module-item-status-icon']"
  end

  def module_item_title_selector
    "[data-testid='module-item-title']"
  end

  def module_item_url_icon_selector(module_item_id)
    "#{module_item_by_id_selector(module_item_id)} [data-testid='url-icon']"
  end

  def module_progression_status_bar_selector(module_id)
    "#{module_header_selector(module_id)} [data-testid='module-progression-status-bar']"
  end

  def module_progression_info_selector(module_id)
    "#{module_header_selector(module_id)} progress"
  end

  def option_list_options_selector(option_list_id)
    "##{option_list_id} [role='option']"
  end

  def page_body
    f("body")
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

  def context_module_expand_toggle_selector(module_id)
    "#{context_module_selector(module_id)} [data-testid='module-header-expand-toggle'][aria-expanded='false']"
  end

  def context_module_collapse_toggle_selector(module_id)
    "#{context_module_selector(module_id)} [data-testid='module-header-expand-toggle'][aria-expanded='true']"
  end

  #------------------------------ Elements ------------------------------

  def context_module(module_id)
    f(context_module_selector(module_id))
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

  def copy_button
    fj(copy_to_button_selector)
  end

  def copy_to_tray_course_select
    f(copy_to_tray_course_select_selector)
  end

  def edit_item_modal
    f(edit_item_modal_selector)
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

  def module_item_action_menu
    f(module_item_action_menu_selector)
  end

  def module_item_action_menu_link(tool_text)
    fj(module_item_action_menu_link_selector(tool_text))
  end

  def module_item_assignment_icon(module_item_id)
    f(module_item_assignment_icon_selector(module_item_id))
  end

  def module_item_by_id(module_item_id)
    f(module_item_by_id_selector(module_item_id))
  end

  def module_item_discussion_icon(module_item_id)
    f(module_item_discussion_icon_selector(module_item_id))
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

  def module_item_page_icon(module_item_id)
    f(module_item_page_icon_selector(module_item_id))
  end

  def module_item_quiz_icon(module_item_id)
    f(module_item_quiz_icon_selector(module_item_id))
  end

  def module_item_status_icon(module_item_id)
    f(module_item_status_icon_selector(module_item_id))
  end

  def module_item_titles
    ff(module_item_title_selector)
  end

  def module_item_url_icon(module_item_id)
    f(module_item_url_icon_selector(module_item_id))
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

  def flash_alert
    f(".flashalert-message")
  end

  #------------------------------ Actions -------------------------------

  def assignments_due_button_exists?
    element_exists?(assignments_due_button_selector)
  end

  def click_assignments_due_button
    assignments_due_button.click
  end

  def course_modules_setup(student_view: false)
    student_view ? set_rewrite_student_flag : set_rewrite_flag
    @quiz = @course.quizzes.create!(title: "some quiz")
    @quiz.publish!
    @assignment = @course.assignments.create!(title: "assignment 1", submission_types: "online_text_entry")
    @assignment2 = @course.assignments.create!(title: "assignment 2",
                                               submission_types: "online_text_entry",
                                               points_possible: 10)
    @assignment3 = @course.assignments.create!(title: "assignment 3", submission_types: "online_text_entry")

    @module1 = @course.context_modules.create!(name: "module1")
    @module2 = @course.context_modules.create!(name: "module2")
    @module_item1 = @module1.add_item({ id: @assignment.id, type: "assignment" })
    @module_item2 = @module1.add_item({ id: @assignment2.id, type: "assignment" })
    @module_item3 = @module2.add_item({ id: @assignment3.id, type: "assignment" })
    @module_item4 = @module2.add_item({ id: @quiz.id, type: "quiz" })

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

  def set_rewrite_flag(rewrite_status: true)
    rewrite_status ? @course.root_account.enable_feature!(:modules_page_rewrite) : @course.root_account.disable_feature!(:modules_page_rewrite)
  end

  def set_rewrite_student_flag(rewrite_status: true)
    rewrite_status ? @course.root_account.enable_feature!(:modules_page_rewrite_student_view) : @course.root_account.disable_feature!(:modules_page_rewrite_student_view)
  end

  def visit_course(course)
    get "/courses/#{course.id}"
  end
end
