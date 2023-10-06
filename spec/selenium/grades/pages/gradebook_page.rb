# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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
require_relative "post_grades_tray_page"
require_relative "hide_grades_tray_page"

module Gradebook
  extend SeleniumDependencies

  # Student Headings
  STUDENT_COLUMN_MENU_SELECTOR = ".container_0 .Gradebook__ColumnHeaderAction"

  # Gradebook Menu
  GRADEBOOK_MENU_SELECTOR = '[data-component="GradebookMenu"]'
  INDIVIDUAL_VIEW_ITEM_SELECTOR = "individual-gradebook"
  GRADE_HISTORY_ITEM_SELECTOR = "gradebook-history"
  LEARING_MASTERY_ITEM_SELECTOR = "learning-mastery"

  # Action Menu
  ACTION_MENU_SELECTOR = '[data-component="ActionMenu"]'
  ACTION_MENU_ITEM_SELECTOR = 'body [data-menu-id="%s"]'

  # Menu Items
  MENU_ITEM_SELECTOR = 'span[data-menu-item-id="%s"]'

  # Keyboard keys
  BACKSPACE_KEY = "\u0008"

  def self.gradebook_settings_cog
    f('[data-testid="gradebook-settings-button"]')
  end

  def self.notes_option
    fj('[role="menuitemcheckbox"]:contains("Notes")')
  end

  def self.split_student_names_option
    fj('[role="menuitemcheckbox"]:contains("Split Student Names")')
  end

  def self.save_button
    fj('button span:contains("Save")')
  end

  def self.grid
    f("#gradebook_grid .container_1")
  end

  # assignment header column elements
  def self.assignment_header_menu_element(id)
    f(".slick-header-column.assignment_#{id} .Gradebook__ColumnHeaderAction")
  end

  def self.assignment_header_menu_item_element(item_name)
    f("span[data-menu-item-id=#{item_name}]")
  end

  def self.assignment_header_popover_menu_element(menu_name)
    fj("button:contains('#{menu_name}')")
  end

  def self.assignment_header_popover_sub_item_element(item)
    fj("span[role=menuitemradio]:contains(#{item})")
  end

  def self.assignment_header_cell_label_element(title)
    select_assignment_header_cell_element(title).find(".assignment-name")
  end

  def self.assignment_menu_selector(menu_text)
    fj("span[role='menuitem']:contains('#{menu_text}')")
  end

  def self.assignment_header(id)
    f(".slick-header-column.assignment_#{id}")
  end

  def self.assignment_hidden_eye_icon(id)
    f("svg[name='IconOff']", assignment_header(id))
  end

  # student header column elements
  def self.student_column_menu
    f("span .Gradebook__ColumnHeaderAction")
  end

  def self.student_header_menu_main_element(menu)
    fj("[role=menu] button:contains('#{menu}')")
  end

  def self.student_header_submenu_item_element(sub_menu_item)
    fj("[role=menuitemradio]:contains('#{sub_menu_item}')")
  end

  def self.student_header_show_menu_option(menu_item)
    fj("[role=menuitemcheckbox]:contains(#{menu_item})")
  end

  def self.student_names
    ff(".student-name")
  end

  def self.student_column_cell_element(x, y)
    f("div .slick-cell.b#{x}.f#{y}.meta-cell")
  end

  def self.total_header_options_menu_item_element(menu_item)
    fj("[role=menuitem]:contains('#{menu_item}')")
  end

  def self.menu_container(container_id)
    selector = "[role=menu]"
    selector += "[aria-labelledby=#{container_id}]" if container_id

    f(selector)
  end

  def self.gradebook_menu(name)
    ff(".gradebook-menus [data-component]").find { |el| el.text.strip =~ /#{name}/ }
  end

  def self.action_menu_item(name)
    f(action_menu_item_selector(name))
  end

  def self.gradebook_dropdown_menu
    fj(GRADEBOOK_MENU_SELECTOR + ":visible")
  end

  def self.grade_input(cell)
    f(".grade", cell)
  end

  def self.link_previous_grade_export
    f('span[data-menu-id="previous-export"]')
  end

  # EVAL-3711 Remove ICE Evaluate feature flag
  def self.link_export(course)
    if course.root_account.feature_enabled?(:instui_nav)
      return ff('[data-component="EnhancedActionMenu"] button')[2]
    end

    ff('[data-component="EnhancedActionMenu"] button')[1]
  end

  def self.link_sync
    ff('[data-component="EnhancedActionMenu"] button')[0]
  end

  # EVAL-3711 Remove ICE Evaluate feature flag
  def self.link_import(course)
    if course.root_account.feature_enabled?(:instui_nav)
      return ff('[data-component="EnhancedActionMenu"] button')[1]
    end

    ff('[data-component="EnhancedActionMenu"] button')[0]
  end

  def self.slick_custom_col_cell
    ff(".slick-cell.custom_column")
  end

  def self.slick_header
    ff(".container_0 .slick-header-column")
  end

  def self.gradebook_view_menu_button
    f('[data-component="ViewOptionsMenu"] button')
  end

  def self.total_cell_warning_icon
    ff(".gradebook-cell .icon-warning")
  end

  def self.gradebook_history
    f('[data-menu-item-id="gradebook-history"]')
  end

  def self.gradebook_menu_element
    f('[data-testid="gradebook-select-dropdown"]')
  end

  def self.gradebook_title
    f('[data-testid="gradebook-title"]')
  end

  def self.gradebook_settings_button
    f('[data-testid="gradebook-settings-button"]')
  end

  def self.filters_element
    fj("li:contains(Filters) button")
  end

  def self.show_grading_period_filter_element
    fxpath("//li[@role='none']//span[contains(text(), 'Grading Periods')]")
  end

  def self.show_module_filter_element
    fxpath("//li[@role='none']//span[contains(text(), 'Modules')]")
  end

  def self.show_section_filter_element
    fxpath("//li[@role='none']//span[contains(text(), 'Sections')]")
  end

  def self.show_unpublished_assignments
    fj('li li:contains("Unpublished Assignments")')
  end

  def self.view_ungraded_as_zero
    fj('li li:contains("View Ungraded as 0")')
  end

  def self.body
    f("body")
  end

  def self.submission_tray_selector
    ".SubmissionTray__Container"
  end

  def self.submission_tray
    f(submission_tray_selector)
  end

  def self.expanded_popover_menu_selector
    '[role="menu"]'
  end

  def self.expanded_popover_menu
    f(expanded_popover_menu_selector)
  end

  def self.grades_uploaded_data
    f("#gradebook_upload_uploaded_data")
  end

  def self.grades_new_upload
    f("#new_gradebook_upload")
  end

  def self.loading_spinner
    f("#spinner")
  end

  def self.post_grades_option
    assignment_menu_selector("Post grades")
  end

  def self.grades_posted_option
    assignment_menu_selector("All grades posted")
  end

  def self.hide_grades_option
    assignment_menu_selector("Hide grades")
  end

  def self.grade_posting_policy_option
    assignment_menu_selector("Grade Posting Policy")
  end

  # actions
  def self.visit(course)
    get "/courses/#{course.id}/gradebook/change_gradebook_version?version=default"
  end

  def self.visit_upload(course)
    get "/courses/#{course.id}/gradebook_uploads/new"
  end

  def self.select_total_column_option(menu_item_id = nil, already_open: false)
    unless already_open
      total_grade_column_header = f("#gradebook_grid .slick-header-column[id*='total_grade']")
      total_grade_column_header.find_element(:css, ".Gradebook__ColumnHeaderAction").click
    end

    if menu_item_id
      f("span[data-menu-item-id='#{menu_item_id}']").click
    end
  end

  def self.open_assignment_options(cell_index)
    assignment_cell = ff("#gradebook_grid .container_1 .slick-header-column")[cell_index]
    driver.action.move_to(assignment_cell).perform
    trigger = assignment_cell.find_element(:css, ".Gradebook__ColumnHeaderAction")
    trigger.click
  end

  def self.grading_cell(x = 0, y = 0)
    row_idx = y + 1
    col_idx = x + 1
    f(".container_1 .slick-row:nth-child(#{row_idx}) .slick-cell:nth-child(#{col_idx})")
  end

  def self.gradebook_cell(x = 0, y = 0)
    grading_cell(x, y).find_element(:css, ".gradebook-cell")
  end

  def self.gradebook_cell_percentage(x = 0, y = 0)
    gradebook_cell(x, y).find_element(:css, ".percentage")
  end

  def self.student_cell(y = 0)
    row_idx = y + 1
    f(".container_0 .slick-row:nth-child(#{row_idx}) .slick-cell")
  end

  def self.student_grades_link(student_cell)
    student_cell.find_element(:css, ".student-grades-link")
  end

  def self.notes_cell(y = 0)
    row_idx = y + 1
    f(".container_0 .slick-row:nth-child(#{row_idx}) .slick-cell.slick-cell:nth-child(2)")
  end

  def self.notes_save_button
    fj('button:contains("Save")')
  end

  def self.select_section(section = nil)
    section = section.name if section.is_a?(CourseSection)
    section ||= ""
    section_dropdown.click
    filter_menu_item(section).click
    wait_for_ajaximations
  end

  def self.select_grading_period(grading_period_name)
    grading_period_dropdown.click
    filter_menu_item(grading_period_name).click
    wait_for_ajaximations
  end

  def self.select_student_group(student_group)
    student_group = student_group.name if student_group.is_a?(Group)
    student_group_dropdown.click
    filter_menu_item(student_group).click
    wait_for_ajaximations
  end

  def self.show_notes
    view_menu = open_gradebook_menu("View")
    select_gradebook_menu_option("Notes", container: view_menu, role: "menuitemcheckbox")
    driver.action.send_keys(:escape).perform
  end

  def self.add_notes
    notes_cell(0).click
    driver.action.send_keys("B").perform
    driver.action.send_keys(:tab).perform
    driver.action.send_keys(:enter).perform

    notes_cell(1).click
    driver.action.send_keys("A").perform
    driver.action.send_keys(:tab).perform
    driver.action.send_keys(:enter).perform

    notes_cell(2).click
    driver.action.send_keys("C").perform
    driver.action.send_keys(:tab).perform
    driver.action.send_keys(:enter).perform
  end

  def self.open_action_menu
    action_menu.click
  end

  def self.select_menu_item(name)
    menu_item(name).click
  end

  def self.action_menu_item_selector(name)
    f(ACTION_MENU_ITEM_SELECTOR % name)
  end

  def self.action_menu
    f(ACTION_MENU_SELECTOR)
  end

  def self.select_notes_option
    notes_option.click
  end

  def self.select_export(course)
    link_export(course).click
  end

  def self.select_sync
    link_sync.click
  end

  def self.select_import(course)
    link_import(course).click
  end

  def self.select_previous_grade_export
    link_previous_grade_export.click
  end

  def self.header_selector_by_col_index(n)
    f(".container_0 .slick-header-column:nth-child(#{n})")
  end

  def self.wait_for_spinner
    begin
      spinner = loading_spinner
      keep_trying_until(3) { (spinner.displayed? == false) }
    rescue Selenium::WebDriver::Error::TimeoutError
      # ignore - sometimes spinner doesn't appear in Chrome
    end
    wait_for_ajaximations
  end

  # Semantic Methods for Gradebook Menus

  def self.open_gradebook_menu(name)
    trigger = f("button", gradebook_menu(name))
    trigger.click

    # return the finder of the popover menu for use elsewhere if needed
    menu_container(trigger.attribute("id"))
  end

  def self.view_options_menu_selector
    gradebook_view_menu_button
  end

  def self.open_view_gradebook_menu
    trigger = view_options_menu_selector
    trigger.click

    # return the finder of the popover menu for use elsewhere if needed
    menu_container(trigger.attribute("id"))
  end

  def self.open_view_menu_and_arrange_by_menu
    view_menu = open_gradebook_menu("View")
    hover(view_menu_item("Arrange By"))
    view_menu
  end

  def self.select_view_ungraded_as_zero(confirm: true)
    view_ungraded_as_zero.click

    if confirm
      confirmation_dialog = f("span[role=dialog][aria-label='View Ungraded as Zero']")
      ok_button = fj("button:contains('OK')", confirmation_dialog)
      ok_button.click
    end
  end

  def self.select_view_dropdown
    view_options_menu_selector.click
  end

  def self.slick_headers_selector
    slick_header
  end

  def self.slick_custom_column_cell_selector
    slick_custom_col_cell
  end

  def self.select_gradebook_menu_option(name, container: nil, role: "menuitemradio")
    gradebook_menu_option(name, container:, role:).click
  end

  def self.gradebook_menu_options(container, role = "menuitemradio")
    ff("[role*=#{role}]", container)
  end

  def self.gradebook_menu_option(name = nil, container: nil, role: "menuitemradio")
    menu_item_name = name
    menu_container = container

    if name =~ /(.+?) > (.+)/
      menu_item_group_name, menu_item_name = Regexp.last_match[1], Regexp.last_match[2]

      menu_container = gradebook_menu_group(menu_item_group_name, container:)
    end

    fj("[role*=#{role}] *:contains(#{menu_item_name})", menu_container)
  end

  def self.gradebook_menu_group(name, container: nil)
    menu_group = ff("[id*=MenuItemGroup]", container).find { |el| el.text.strip =~ /#{name}/ }
    return unless menu_group

    menu_group_id = menu_group.attribute("id")
    f("[role=group][aria-labelledby=#{menu_group_id}]")
  end

  def self.menu_item(name)
    f(MENU_ITEM_SELECTOR % name)
  end

  def self.settings_cog_select
    gradebook_settings_cog.click
  end

  def self.view_arrange_by_submenu_item(name)
    fj("[role=menuitemradio]:contains(#{name})")
  end

  def self.view_menu_item(name)
    fj("[role=menu] li:contains(#{name})")
  end

  def self.popover_menu_item_checked?(menu_item_name)
    menu_item = view_arrange_by_submenu_item(menu_item_name)
    menu_item.attribute("aria-checked")
  end

  def self.total_cell_warning_icon_select
    total_cell_warning_icon
  end

  def self.open_display_dialog
    select_total_column_option("grade-display-switcher")
  end

  def self.close_display_dialog
    f(".ui-icon-closethick").click
  end

  def self.toggle_grade_display
    open_display_dialog
    dialog = fj(".ui-dialog:visible")
    submit_dialog(dialog, ".ui-button")
  end

  def self.close_dialog_and_dont_show_again
    dialog = fj(".ui-dialog:visible")
    fj("#hide_warning").click
    submit_dialog(dialog, ".ui-button")
  end

  def self.content_selector
    f("#content")
  end

  def self.assignment_header_cell_selector(title)
    ".slick-header-column[title=\"#{title}\"]"
  end

  def self.grading_period_dropdown_selector
    "#grading-periods-filter-container input"
  end

  def self.grading_period_dropdown
    f(grading_period_dropdown_selector)
  end

  def self.section_dropdown
    f("#sections-filter-container input")
  end

  def self.module_dropdown
    f("#modules-filter-container input")
  end

  def self.student_group_dropdown
    f("#student-group-filter-container input")
  end

  def self.filter_menu_item(menu_item_name)
    wait_for_animations
    fj("[role=\"option\"]:contains(\"#{menu_item_name}\")")
  end

  def self.gradebook_dropdown_item_click(menu_item_name)
    gradebook_menu_element.click

    case menu_item_name
    when "Individual View"
      menu_item(INDIVIDUAL_VIEW_ITEM_SELECTOR).click
    when "Learning Mastery"
      menu_item(LEARING_MASTERY_ITEM_SELECTOR).click
    when "Gradebook History"
      menu_item(GRADE_HISTORY_ITEM_SELECTOR).click
    end
  end

  def self.module_dropdown_item_click(menu_item_name)
    module_dropdown.click
    filter_menu_item(menu_item_name).click
  end

  def self.gradebook_settings_btn_select
    gradebook_settings_button.click
  end

  def self.scores_scraped
    class_names = ff(".total-cell.total_grade").map { |grade| fxpath("..", grade).attribute("class") }
    user_ids = class_names.map { |name| name.match("student_([0-9]+)")[1] }
    total_grades = ff(".total-cell.total_grade .grades").map { |grade| grade.text.split("%")[0] }
    total_grades.map.with_index { |grade, index| { user_id: user_ids[index].to_i, score: grade.to_f } }
  end

  def self.scores_api(course)
    scores = Score.joins(:enrollment).merge(course.student_enrollments).where(course_score: true)
    enrollments = course.student_enrollments
    scores.map do |score|
      {
        user_id: enrollments.find(score.enrollment_id).user_id,
        score: score.current_score
      }
    end
  end

  # STUDENT COLUMN HEADER OPTIONS
  def self.student_header_menu_option_select(name)
    student_header_show_menu_option(name).click
  end

  def self.click_student_menu_sort_by(menu_option)
    student_column_menu.click
    hover(student_header_menu_main_element("Sort by"))
    wait_for_ajaximations

    case menu_option
    when "A-Z"
      student_header_submenu_item_element("A–Z").click
    when "Z-A"
      student_header_submenu_item_element("Z–A").click
    end
  end

  def self.click_student_menu_display_as(menu_option)
    student_column_menu.click
    hover(student_header_menu_main_element("Display as"))

    case menu_option
    when "First,Last"
      student_header_submenu_item_element("First, Last Name").click
    when "Last,First"
      student_header_submenu_item_element("Last, First Name").click
    when "Anonymous"
      student_header_submenu_item_element("Anonymous").click
    end
  end

  def self.click_student_menu_secondary_info(menu_option)
    student_column_menu.click
    hover(student_header_menu_main_element("Secondary info"))

    case menu_option
    when "Section"
      student_header_submenu_item_element("Section").click
    when "SIS"
      student_header_submenu_item_element("SIS ID").click
    when "Login"
      student_header_submenu_item_element("Login ID").click
    when "None"
      student_header_submenu_item_element("None").click
    end
  end

  def self.click_student_header_menu_show_option(name)
    student_column_menu.click
    student_header_show_menu_option(name).click
  end

  def self.fetch_student_names
    student_names.map(&:text)
  end

  def self.student_column_cell_select(x, y)
    student_column_cell_element(x, y)
  end

  # ASSIGNMENT COLUMN HEADER OPTIONS
  # css selectors
  def self.assignment_header_cell_element(title)
    f(assignment_header_cell_selector(title))
  end

  def self.assignment_names
    ff(".assignment-name")
  end

  def self.fetch_assignment_names
    assignment_names.map(&:text)
  end

  def self.assignment_header_menu_trigger_element(assignment_name)
    assignment_header_cell_element(assignment_name).find_element(:css, ".Gradebook__ColumnHeaderAction button")
  end

  def self.assignment_header_menu_item_selector(item)
    menu_item_id = ""

    case item
    when /curve(-?\s?grade)?/i
      menu_item_id = "curve-grades"
    when /set(-?\s?default-?\s?grade)?/i
      menu_item_id = "set-default-grade"
    end

    assignment_header_menu_item_element(menu_item_id)
  end

  def self.close_open_dialog
    fj(".ui-dialog-titlebar-close:visible").click
  end

  def self.select_filters
    hover(filters_element)
  end

  def self.select_view_filter(filter)
    case filter
    when "Grading Periods"
      show_grading_period_filter_element.click
    when "Modules"
      show_module_filter_element.click
    when "Sections"
      show_section_filter_element.click
    end
  end

  def self.select_show_unpublished_assignments
    show_unpublished_assignments.click
  end

  def self.assignment_group_header_options_element(group_name)
    fj("[title='#{group_name}'] .Gradebook__ColumnHeaderAction")
  end

  def self.click_assignment_header_menu(assignment_id)
    assignment_header_menu_element(assignment_id).click
  end

  def self.click_assignment_header_menu_element(assignment_id, menuitem)
    assignment_header_menu_element(assignment_id).click
    menu_item_id = ""

    case menuitem
    when /(message(-?\s?student)?)/i
      menu_item_id = "message-students-who"
    when /(curve(-?\s?grade)?)/i
      menu_item_id = "curve-grades"
    when /(set(-?\s?default-?\s?grade)?)/i
      menu_item_id = "set-default-grade"
    when /(download(-?\s?submission)?)/i
      menu_item_id = "download-submissions"

    end
    assignment_header_menu_item_element(menu_item_id).click
  end

  def self.click_assignment_popover_sort_by(sort_type)
    assignment_header_popover_menu_element("Sort by").click # focus it
    assignment_header_popover_menu_element("Sort by").click # open it

    sort_by_item = ""

    case sort_type
    when /(low[\s-]to[\s-]high)/i
      sort_by_item = "Grade - Low to High"
    when /(high[\s-]to[\s-]low)/i
      sort_by_item = "Grade - High to Low"
    when /(missing)/i
      sort_by_item = "Missing"
    when /(late)/i
      sort_by_item = "Late"
    when /(unposted)/i
      sort_by_item = "Unposted"
    end
    assignment_header_popover_sub_item_element(sort_by_item).click
    driver.action.send_keys(:escape).perform
  end

  def self.click_assignment_popover_enter_grade_as(assignment_id, grade_type)
    assignment_header_menu_element(assignment_id).click
    hover(assignment_header_popover_menu_element("Enter Grades as"))
    assignment_header_popover_sub_item_element(grade_type).click
  end

  def self.enter_grade_as_popover_menu_item_checked?(grade_type)
    hover(assignment_header_popover_menu_element("Enter Grades as"))
    menu_item = assignment_header_popover_sub_item_element(grade_type)
    menu_item.attribute("aria-checked")
  end

  def self.select_assignment_header_cell_element(name)
    f(assignment_header_cell_selector(name))
  end

  def self.select_assignment_header_secondary_label(name)
    fj(assignment_header_cell_selector(name) + " .Gradebook__ColumnHeaderDetail--secondary")
  end

  def self.select_assignment_header_cell_label_element(name)
    assignment_header_cell_label_element(name)
  end

  def self.click_assignment_group_header_options(group_name, sort_type)
    assignment_group_header_options_element(group_name).click
    hover(student_header_menu_main_element("Sort by"))

    case sort_type
    when "Grade - High to Low"
      student_header_submenu_item_element("Grade - High to Low").click
    when "Grade - Low to High"
      student_header_submenu_item_element("Grade - Low to High").click
    end
  end

  def self.click_total_header_sort_by(sort_type)
    select_total_column_option
    hover(student_header_menu_main_element("Sort by"))

    case sort_type
    when "Grade - High to Low"
      student_header_submenu_item_element("Grade - High to Low").click
    when "Grade - Low to High"
      student_header_submenu_item_element("Grade - Low to High").click
    end
  end

  def self.click_total_header_menu_option(main_menu)
    select_total_column_option
    case main_menu
    when "Move to Front"
      total_header_options_menu_item_element("Move to Front").click
    when "Move to End"
      total_header_options_menu_item_element("Move to End").click
    when "Display as Points"
      total_header_options_menu_item_element("Display as Points").click
    end
  end

  def self.gradebook_slick_header_columns
    ff(".slick-header-column").map(&:text)
  end

  def self.overlay_info_screen
    fj(".overlay_screen")
  end

  def self.click_post_grades(assignment_id)
    click_assignment_header_menu(assignment_id)
    post_grades_option.click
    PostGradesTray.full_content
  end

  def self.click_hide_grades(assignment_id)
    click_assignment_header_menu(assignment_id)
    # TODO: click hide grades
    hide_grades_option.click
    HideGradesTray.full_content
    HideGradesTray.hide_button
  end

  def self.click_grade_posting_policy(assignment_id)
    click_assignment_header_menu(assignment_id)
    # TODO: click posting policy
    grade_posting_policy_option.click
    Gradebook::AssignmentPostingPolicy
  end

  def self.manually_post_grades(assignment, type, section = nil)
    Gradebook.click_post_grades(assignment.id)
    PostGradesTray.post_type_radio_button(type).click
    PostGradesTray.select_section(section.name) unless section.nil?
    PostGradesTray.post_grades
  end

  delegate :click, to: :save_button, prefix: true

  # ENHANCED GRADEBOOK FILTERS

  def self.apply_filters_button
    f('[data-testid="apply-filters-button"]')
  end

  def self.students_filter_select
    f('[data-testid="students-filter-select"]')
  end

  def self.assignments_filter_select
    f('[data-testid="assignments-filter-select"]')
  end

  def self.remove_student_or_assignment_filter(name)
    f("[title='Remove #{name}']").click
  end

  def self.select_filter_type_menu_item(item_name)
    f("[data-testid=\"#{item_name}-filter-type\"]").click
  end

  def self.select_filter_menu_item(item_name)
    f("[data-testid=\"#{item_name}-filter\"]").click
  end

  def self.select_filter_dropdown_back_button
    f('[data-testid="back-button"]').click
  end

  def self.select_sorted_filter_menu_item(item_name)
    f("[data-testid=\"#{item_name}-sorted-filter\"]").click
  end

  def self.start_date_input
    f("[data-testid='start-date-input']")
  end

  def self.end_date_input
    f("[data-testid='end-date-input']")
  end

  def self.input_start_date(date)
    start_date_input.send_keys(date.to_s)
  end

  def self.input_end_date(date)
    end_date_input.send_keys(date.to_s)
  end

  def self.apply_date_filter
    f("[data-testid='apply-date-filter']").click
  end

  def self.clear_start_date_input
    start_date_input.send_keys(BACKSPACE_KEY * start_date_input.attribute("value").length)
  end

  def self.clear_end_date_input
    end_date_input.send_keys(BACKSPACE_KEY * end_date_input.attribute("value").length)
  end

  def self.clear_filter(filter_name)
    f("[data-testid='applied-filter-#{filter_name}']").click
  end

  def self.filter_pill(filter_name)
    f("[data-testid='applied-filter-#{filter_name}']")
  end

  def self.manage_filter_presets_button
    f("[data-testid='manage-filter-presets-button']")
  end

  def self.create_filter_preset_dropdown
    f("[data-testid='create-filter-preset-dropdown']").find_element(:css, "button")
  end

  def self.filter_preset_dropdown_type(filter_type)
    f("[data-testid='select-filter-#{filter_type}']")
  end

  def self.select_filter_preset_dropdown_option(filter_type, filter_option)
    click_option(f("[data-testid='select-filter-#{filter_type}']"), filter_option)
  end

  def self.input_preset_filter_name(name)
    f("[data-testid='filter-preset-name-input']").send_keys(name)
  end

  def self.save_filter_preset
    f("[data-testid='save-filter-button']").click
  end

  def self.delete_filter_preset_button
    f("[data-testid='delete-filter-preset-button']")
  end

  def self.filter_preset_dropdown(name)
    f("[data-testid='#{name}-dropdown']").find_element(:css, "button")
  end

  def self.enable_filter_preset(name)
    f("[data-testid='#{name}-enable-preset']").click
  end

  def self.clear_all_filters
    f("[data-testid='clear-all-filters']").click
  end
end
