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

  def collapse_all_modules_button_selector
    "button[aria-label='Collapse All']"
  end

  def edit_item_modal_selector
    "[data-testid='edit-item-modal']"
  end

  def expand_all_modules_button_selector
    "button[aria-label='Expand All']"
  end

  def manage_module_item_button_selector(module_item_id)
    "[data-testid='module-item-action-menu_#{module_item_id}']"
  end

  def manage_module_item_container_selector(module_item_id)
    "#context_module_item_#{module_item_id}"
  end

  def module_action_menu_selector(module_id)
    "[data-testid='module-action-menu_#{module_id}']"
  end

  def module_header_expand_toggle_selector
    "[data-testid='module-header-expand-toggle']"
  end

  def module_item_action_menu_link_selector(tool_text)
    "[role=menuitem]:contains('#{tool_text}')"
  end

  def module_item_title_selector
    "[data-testid='module-item-title']"
  end

  def module_item_action_menu_selector
    "[data-testid='module-item-action-menu']"
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

  #------------------------------ Elements ------------------------------

  def collapse_all_modules_button
    f(collapse_all_modules_button_selector)
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

  def module_action_menu(module_id)
    f(module_action_menu_selector(module_id))
  end

  def module_header_expand_toggles
    ff(module_header_expand_toggle_selector)
  end

  def module_item_action_menu
    f(module_item_action_menu_selector)
  end

  def module_item_action_menu_link(tool_text)
    fj(module_item_action_menu_link_selector(tool_text))
  end

  def module_item_titles
    ff(module_item_title_selector)
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

  #------------------------------ Actions -------------------------------

  def set_rewrite_flag(rewrite_status: true)
    rewrite_status ? @course.root_account.enable_feature!(:modules_page_rewrite) : @course.root_account.disable_feature!(:modules_page_rewrite)
  end

  def set_rewrite_student_flag(rewrite_status: true)
    rewrite_status ? @course.root_account.enable_feature!(:modules_page_rewrite_student_view) : @course.root_account.disable_feature!(:modules_page_rewrite_student_view)
  end

  def modules2_teacher_setup
    course_with_teacher(active_all: true)
    course_modules_setup
  end

  def modules2_student_setup
    course_with_student(active_all: true)
    course_modules_setup(student_view: true)
  end

  def course_modules_setup(student_view: false)
    student_view ? set_rewrite_student_flag : set_rewrite_flag
    @quiz = @course.quizzes.create!(title: "some quiz")
    @quiz.publish!
    @assignment = @course.assignments.create!(title: "assignment 1", submission_types: "online_text_entry")
    @assignment2 = @course.assignments.create!(title: "assignment 2",
                                               submission_types: "online_text_entry",
                                               due_at: 2.days.from_now,
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

  def visit_course(course)
    get "/courses/#{course.id}"
  end
end
