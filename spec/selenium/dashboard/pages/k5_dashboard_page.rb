# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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
require_relative '../../helpers/color_common'

module K5PageObject
  include ColorCommon

  #------------------------- Selectors --------------------------
  def enable_homeroom_checkbox_selector
    '#course_homeroom_course'
  end

  def welcome_title_selector
    'h1'
  end

  def course_dashboard_title_selector
    'h1'
  end

  def homeroom_tab_selector
    '#tab-tab-homeroom'
  end

  def schedule_tab_selector
    '#tab-tab-schedule'
  end

  def grades_tab_selector
    '#tab-tab-grades'
  end

  def resources_tab_selector
    '#tab-tab-resources'
  end

  def home_tab_selector
    '#tab-tab-home'
  end

  def modules_tab_selector
    '#tab-tab-modules'
  end

  def course_card_selector(course_title)
    "div[title='#{course_title}']"
  end

  def announcement_on_card_xpath_selector(announcement_title)
    "//div[@class = 'ic-DashboardCard']//span[text() = '#{announcement_title}']"
  end

  def subject_link_selector(subject_title)
    "//a[div[@title = '#{subject_title}']]"
  end

  def items_due_selector(subject_title, due_today_text)
    "//*[@aria-label = '#{subject_title}']//*[text() = '#{due_today_text}']"
  end

  def items_missing_selector(subject_title, number_items_missing)
    "//*[@aria-label = '#{subject_title}']//*[text() = '#{number_items_missing} missing']"
  end

  def today_selector
    "h2 div:contains('Today')"
  end

  def homeroom_course_title_selector(title)
    "h2:contains('#{title}')"
  end

  def announcement_title_selector(announcement_title)
    "h3:contains('#{announcement_title}')"
  end

  def announcement_content_text_selector(content_text)
    "div:contains('#{content_text}')"
  end

  def announcement_button_selector
    "//a[*//. = 'Announcement']"
  end

  def announcement_edit_button_selector
    "a[cursor='pointer']"
  end

  def staff_selector(staff_name)
    "h3:contains('#{staff_name}')"
  end

  def instructor_role_selector(inst_role)
    "//*[@data-automation = 'instructor-role' and text() = '#{inst_role}']"
  end

  def instructor_bio_selector(inst_bio)
    "//*[@data-automation = 'instructor-bio' and text() = '#{inst_bio}']"
  end

  def email_link_selector(email_address)
    "a[href = 'mailto:#{email_address}']"
  end

  def grade_title_selector(title)
    "div:contains('#{title}')"
  end

  def subject_grade_selector(value)
    "//*[@data-automation = 'course_grade' and text() = '#{value}']"
  end

  def grade_progress_bar_selector(value)
    "//*[@role = 'progressbar' and @value = '#{value}']"
  end

  def view_grades_button_selector(course_id)
    "a[href = '/courses/#{course_id}/gradebook']"
  end

  def grading_period_dropdown_selector
    "#grading-period-select"
  end

  def week_date_selector
    "h2 div"
  end

  def teacher_preview_selector
    "h2:contains('Teacher Schedule Preview')"
  end

  def previous_week_button_selector
    "//button[.//span[. = 'View previous week']]"
  end

  def next_week_button_selector
    "//button[.//span[. = 'View next week']]"
  end

  def today_button_selector
    "//button[.//span[. = 'Today']]"
  end

  def missing_dropdown_selector
    "[data-testid = 'missing-item-info']"
  end

  def missing_data_selector
    "[data-testid = 'missing-data']"
  end

  def missing_assignments_selector
    ".MissingAssignments-styles__root .PlannerItem-styles__title"
  end

  def assignment_url_selector(course_id, assignment_id)
    "a[href = '/courses/#{course_id}/assignments/#{assignment_id}']"
  end

  def message_button_selector
    "//button[.//*[contains(text(),'Send a message to')]]"
  end

  def subject_input_selector
    "input[placeholder = 'No subject']"
  end

  def message_input_selector
    "textarea[placeholder = 'Message']"
  end

  def send_button_selector
    "//button[.//*[. = 'Send']]"
  end

  def cancel_button_selector
    "//button[.//*[. = 'Cancel']]"
  end

  def message_modal_selector(user_name)
    "[aria-label='Message #{user_name}']"
  end

  def k5_app_button_selector
    "[data-testid='k5-app-button']"
  end

  def course_selection_modal_selector
    "[aria-label='Choose a Course']"
  end

  def course_list_selector
    "//*[@aria-label = 'Choose a Course']//a"
  end

  def dashboard_card_selector
    "[data-testid='k5-dashboard-card-hero']"
  end

  def dashboard_header_selector
    "[data-testid='k5-course-header-hero']"
  end

  def front_page_info_selector
    "#course_home_content .user_content"
  end

  def manage_button_selector
    "[data-testid = 'manage-button']"
  end

  def course_navigation_tray_selector
    "[aria-label='Course Navigation Tray']"
  end

  def course_nav_tray_close_selector
    "//button[.//*[. = 'Close']]"
  end

  def no_module_content_selector
    "#no_context_modules_message"
  end

  def module_item_selector(module_title)
    "[title='#{module_title}']"
  end

  def expand_collapse_module_selector
    "#expand_collapse_all"
  end

  def module_assignment_selector(module_assignment_title)
    "[title='#{module_assignment_title}']"
  end

  def assignment_page_title_selector
    "h1"
  end

  def module_empty_state_button_selector
    ".ic-EmptyStateButton"
  end

  def assignment_edit_button_selector
    ".edit_assignment_link"
  end

  def add_module_button_selector
    ".add_module_link"
  end

  def add_module_modal_selector
    "#add_context_module_form"
  end

  def add_module_item_button_selector
    ".add_module_item_link"
  end

  def add_module_item_modal_selector
    "#select_context_content_dialog"
  end

  def drag_handle_selector
    "[title='Drag to reorder or move item to another module']"
  end

  def schedule_item_selector
    ".PlannerItem-styles__title a"
  end

  def missing_item_href_selector(course_id, assignment_id)
    "//*[contains(@href, '/courses/#{course_id}/assignments/#{assignment_id}')]"
  end

  def new_course_button_selector
    "[data-testid='new-course-button']"
  end

  def new_course_modal_selector
    "[aria-label='Create Course']"
  end

  def new_course_modal_close_button_selector
    "[data-testid='instui-modal-close']"
  end

  def account_name_selector
    "[placeholder='Begin typing to search']"
  end

  def course_name_input_selector
    "[placeholder='Name...']"
  end

  def new_course_modal_create_selector
    "//button[.//*[. = 'Create']]"
  end

  def new_course_modal_cancel_selector
    "//button[.//*[. = 'Cancel']]"
  end

  def empty_grades_image_selector
    "[data-testid='empty-grades-panda']"
  end

  def assignment_group_toggle_selector
    "[data-testid='assignment-group-toggle']"
  end

  def grades_total_selector
    "[data-testid='grades-total']"
  end

  def grades_table_row_selector
    "[data-testid='grades-table-row']"
  end

  def grades_assignment_anchor_selector
    "a"
  end

  def pink_color_button_selector
    "//button[contains(@id,'DF6B91')]"
  end

  def selected_color_input_selector
    "[name='course[course_color]']"
  end

  def course_color_preview_selector
    "[data-testid='course-color-preview']"
  end

  def planner_assignment_header_selector
    ".Grouping-styles__overlay"
  end

  def new_grade_badge_selector
    "[data-testid='new-grade-indicator']"
  end

  #------------------------- Elements --------------------------

  def enable_homeroom_checkbox
    f(enable_homeroom_checkbox_selector)
  end

  def welcome_title
    f(welcome_title_selector)
  end

  def course_dashboard_title
    f(course_dashboard_title_selector)
  end

  def homeroom_tab
    f(homeroom_tab_selector)
  end

  def schedule_tab
    f(schedule_tab_selector)
  end

  def grades_tab
    f(grades_tab_selector)
  end

  def resources_tab
    f(resources_tab_selector)
  end

  def home_tab
    f(home_tab_selector)
  end

  def modules_tab
    f(modules_tab_selector)
  end

  def course_card(course_title)
    f("div[title='#{course_title}']")
  end

  def course_card_announcement(course_title)
    fxpath(announcement_on_card_xpath_selector(course_title))
  end

  def subject_title_link(subject_title)
    fxpath(subject_link_selector(subject_title))
  end

  def subject_items_due(subject_title, due_today_text)
    fxpath(items_due_selector(subject_title, due_today_text))
  end

  def subject_items_missing(subject_title, number_items_missing)
    fxpath(items_missing_selector(subject_title, number_items_missing))
  end

  def today_header
    fj(today_selector)
  end

  def homeroom_course_title(title)
    fj(homeroom_course_title_selector(title))
  end

  def homeroom_course_title_link(title)
    fln(title)
  end

  def announcement_title(announcement_title)
    fj(announcement_title_selector(announcement_title))
  end

  def announcement_content_text(content_text)
    fj(announcement_content_text_selector(content_text))
  end

  def announcement_button
    fxpath(announcement_button_selector)
  end

  def announcement_edit_pencil
    f(announcement_edit_button_selector)
  end

  def staff_heading(staff_name)
    fj(staff_selector(staff_name))
  end

  def email_link(email_address)
    f(email_link_selector(email_address))
  end

  def instructor_role(role_type)
    fxpath(instructor_role_selector(role_type))
  end

  def instructor_bio(instructor_bio)
    fxpath(instructor_bio_selector(instructor_bio))
  end

  def subject_grades_title(title)
    fj(grade_title_selector(title))
  end

  def subject_grade(grade_value)
    fxpath(subject_grade_selector(grade_value))
  end

  def grade_progress_bar(grade_value)
    fxpath(grade_progress_bar_selector(grade_value))
  end

  def view_grades_button(course_id)
    f(view_grades_button_selector(course_id))
  end

  def grading_period_dropdown
    f(grading_period_dropdown_selector)
  end

  def teacher_preview
    fj(teacher_preview_selector)
  end

  def beginning_of_week_date
    date_block = ff(week_date_selector)
    date_block[0].text == 'Today' ? date_block[1].text : date_block[0].text
  end

  def end_of_week_date
    ff(week_date_selector).last.text
  end

  def previous_week_button
    fxpath(previous_week_button_selector)
  end

  def next_week_button
    fxpath(next_week_button_selector)
  end

  def today_button
    fxpath(today_button_selector)
  end

  def items_missing
    f(missing_dropdown_selector)
  end

  def items_missing_exists?
    element_exists?(missing_dropdown_selector)
  end

  def missing_data
    f(missing_data_selector)
  end

  def missing_data_exists?
    element_exists?(missing_data_selector)
  end

  def missing_assignments
    ff(missing_assignments_selector)
  end

  def assignment_url(assignment_title)
    fj(assignment_url_selector(assignment_title))
  end

  def message_button
    fxpath(message_button_selector)
  end

  def subject_input
    f(subject_input_selector)
  end

  def message_input
    f(message_input_selector)
  end

  def send_button
    fxpath(send_button_selector)
  end

  def cancel_button
    fxpath(cancel_button_selector)
  end

  def message_modal(user_name)
    f(message_modal_selector(user_name))
  end

  def k5_app_buttons
    ff(k5_app_button_selector)
  end

  def course_selection_modal
    f(course_selection_modal_selector)
  end

  def course_list
    ffxpath(course_list_selector)
  end

  def dashboard_card
    f(dashboard_card_selector)
  end

  def front_page_info
    f(front_page_info_selector)
  end

  def manage_button
    f(manage_button_selector)
  end

  def course_navigation_tray
    f(course_navigation_tray_selector)
  end

  def course_nav_tray_close
    fxpath(course_nav_tray_close_selector)
  end

  def assignments_link
    fln('Assignments')
  end

  def no_module_content
    f(no_module_content_selector)
  end

  def module_item(module_title)
    f(module_item_selector(module_title))
  end

  def expand_collapse_module
    f(expand_collapse_module_selector)
  end

  def module_assignment(assignment_title)
    f(module_assignment_selector(assignment_title))
  end

  def assignment_page_title
    f(assignment_page_title_selector)
  end

  def module_empty_state_button
    f(module_empty_state_button_selector)
  end

  def assignment_edit_button
    f(assignment_edit_button_selector)
  end

  def add_module_button
    f(add_module_button_selector)
  end

  def add_module_modal
    f(add_module_modal_selector)
  end

  def add_module_item_button
    f(add_module_item_button_selector)
  end

  def add_module_item_modal
    f(add_module_item_modal_selector)
  end

  def drag_handle
    f(drag_handle_selector)
  end

  def schedule_item
    f(schedule_item_selector)
  end

  def assignment_link(missing_assignment_element, course_id, assignment_id)
    find_from_element_fxpath(missing_assignment_element, missing_item_href_selector(course_id, assignment_id))
  end

  def new_course_button
    f(new_course_button_selector)
  end

  def new_course_modal
    f(new_course_modal_selector)
  end

  def new_course_modal_close_button
    f(new_course_modal_close_button_selector)
  end

  def account_name_element
    f(account_name_selector)
  end

  def course_name_input
    f(course_name_input_selector)
  end

  def new_course_modal_create
    fxpath(new_course_modal_create_selector)
  end

  def new_course_modal_cancel
    fxpath(new_course_modal_cancel_selector)
  end

  def empty_grades_image
    f(empty_grades_image_selector)
  end

  def grades_total
    f(grades_total_selector)
  end

  def grades_assignments_list
    ff(grades_table_row_selector)
  end

  def grades_assignment_href(grade_row_element)
    element_value_for_attr(grade_row_element.find_element(:css, grades_assignment_anchor_selector), "href")
  end

  def pink_color_button
    fxpath(pink_color_button_selector)
  end

  def selected_color_input
    f(selected_color_input_selector)
  end

  def course_color_preview
    f(course_color_preview_selector)
  end

  def dashboard_header
    f(dashboard_header_selector)
  end

  def planner_assignment_header
    f(planner_assignment_header_selector)
  end

  def new_grade_badge
    f(new_grade_badge_selector)
  end

  #----------------------- Actions & Methods -------------------------


  #----------------------- Click Items -------------------------------

  def check_enable_homeroom_checkbox
    enable_homeroom_checkbox.click
  end

  def select_homeroom_tab
    homeroom_tab.click
  end

  def select_home_tab
    home_tab.click
  end

  def select_schedule_tab
    schedule_tab.click
  end

  def select_grades_tab
    grades_tab.click
  end

  def select_resources_tab
    resources_tab.click
  end

  def navigate_to_subject(subject_title)
    subject_title_link(subject_title).click
  end

  def click_homeroom_course_title(course_title)
    homeroom_course_title_link(course_title).click
  end

  def click_announcement_button
    announcement_button.click
  end

  def click_announcement_edit_pencil
    announcement_edit_pencil.click
  end

  def click_previous_week_button
    previous_week_button.click
  end

  def click_next_week_button
    next_week_button.click
  end

  def click_today_button
    today_button.click
  end

  def click_missing_items
    items_missing.click
  end

  def click_message_button
    message_button.click
  end

  def click_send_button
    send_button.click
  end

  def click_cancel_button
    cancel_button.click
  end

  def click_k5_button(button_item)
    k5_app_buttons[button_item].click
  end

  def click_dashboard_card
    dashboard_card.click
  end

  def click_manage_button
    manage_button.click
    wait_for(method: nil, timeout: 2) { course_navigation_tray }
  end

  def click_nav_tray_close
    course_nav_tray_close.click
    wait_for_ajaximations
  end

  def click_assignments_link
    assignments_link.click
  end

  def click_expand_collapse
    expand_collapse_module.click
  end

  def click_module_assignment(assignment_title)
    module_assignment(assignment_title).click
  end

  def click_add_module_button
    add_module_button.click
  end

  def click_add_module_item_button
    add_module_item_button.click
  end

  def click_new_course_button
    new_course_button.click
  end

  def click_new_course_close_button
    new_course_modal_close_button.click
  end

  def select_account_from_list(account_name)
    click_option(account_name_selector, account_name)
  end

  def click_new_course_create
    new_course_modal_create.click
  end

  def click_new_course_cancel
    new_course_modal_cancel.click
  end

  def click_pink_color_button
    pink_color_button.click
  end

  #------------------------------Retrieve Text----------------------#

  def retrieve_welcome_text
    welcome_title.text
  end

  def retrieve_title_text
    course_dashboard_title.text
  end

  def k5_resource_button_names_list
    k5_app_buttons.map(&:text)
  end

  def grades_total_text
    grades_total.text
  end

  #----------------------------Element Management---------------------#

  def announcement_button_exists?
    element_exists?(announcement_button_selector, true)
  end

  def assignment_link_exists?(course_id, assignment_id)
    element_exists?(assignment_url_selector(course_id, assignment_id))
  end

  def missing_assignments_exist?
    element_exists?(missing_assignments_selector)
  end

  def is_send_available?
    element_value_for_attr(send_button, 'cursor') == 'pointer'
  end

  def is_cancel_available?
    element_value_for_attr(cancel_button, 'cursor') == 'pointer'
  end

  def is_modal_gone?(user_name)
    wait_for_no_such_element { message_modal(user_name) }
  end

  def message_modal_displayed?(user_name)
    element_exists?(message_modal_selector(user_name))
  end

  def course_navigation_tray_exists?
    element_exists?(course_navigation_tray_selector)
  end

  def modules_tab_exists?
    element_exists?(modules_tab_selector)
  end

  def module_assignment_exists?(assignment_title)
    element_exists?(module_assignment_selector(assignment_title))
  end

  def beginning_weekday_calculation(current_date)
    (current_date.beginning_of_week(:sunday)).strftime("%B %-d")
  end

  def ending_weekday_calculation(current_date)
    (current_date.end_of_week(:sunday)).strftime("%B %-d")
  end

  def schedule_item_exists?
    element_exists?(schedule_item_selector)
  end

  def new_course_modal_exists?
    element_exists?(new_course_modal_selector)
  end

  def enter_account_search_data(search_term)
    replace_content(account_name_element, search_term)
    driver.action.send_keys(:enter).perform
  end

  def enter_course_name(course_name)
    replace_content(course_name_input, course_name)
    driver.action.send_keys(:enter).perform
  end

  def fill_out_course_modal(course_name)
    enter_account_search_data(@account.name[0...3])
    select_account_from_list(@account.name)
    enter_course_name(course_name)
  end

  def input_color_hex_value(hex_value)
    selected_color_input.send_keys(hex_value)
  end

  #----------------------------Create Content---------------------#

  def new_announcement(course, title, message)
    course.announcements.create!(title: title, message: message)
  end

  def create_lti_resource(resource_name)
    rendered_icon='https://lor.instructure.com/img/icon_commons.png'
    lti_resource_url='http://www.example.com'
    tool =
      Account.default.context_external_tools.new(
        {
          name: resource_name,
          domain: 'canvaslms.com',
          consumer_key: '12345',
          shared_secret: 'secret',
          is_rce_favorite: 'true'
        }
      )
    tool.set_extension_setting(
      :editor_button,
      {
        message_type: 'ContentItemSelectionRequest',
        url: lti_resource_url,
        icon_url: rendered_icon,
        text: "#{resource_name} Favorites",
        enabled: 'true',
        use_tray: 'true',
        favorite: 'true'
      }
    )
    tool.course_navigation = {enabled: true}
    tool.save!
    tool
  end

  def create_dated_assignment(course, assignment_title, assignment_due_at, points_possible = 100)
    course.assignments.create!(
      title: assignment_title,
      grading_type: 'points',
      points_possible: points_possible,
      due_at: assignment_due_at,
      submission_types: 'online_text_entry'
    )
  end

  def feature_setup
    @account = Account.default
    @account.enable_feature!(:canvas_for_elementary)
    toggle_k5_setting(@account)
  end

  def student_setup
    feature_setup
    @course_name = "K5 Course"
    @teacher_name = 'K5Teacher'
    course_with_teacher(
      active_course: 1,
      active_enrollment: 1,
      course_name: @course_name,
      name: @teacher_name,
      email: 'teacher_person@example.com'
    )
    @homeroom_teacher = @teacher
    course_with_student(
      active_all: true,
      new_user: true,
      user_name: 'KTStudent',
      course: @course
    )
    @course.update!(homeroom_course: true)
    @homeroom_course = @course

    @subject_course_title = "Science"
    course_with_student(
      active_all: true,
      user: @student,
      course_name: @subject_course_title
    )
    @subject_course = @course
  end

  def teacher_setup
    feature_setup
    @course_name = "K5 Course"
    course_with_teacher(
      active_course: 1,
      active_enrollment: 1,
      course_name: @course_name,
      name: 'K5Teacher'
    )
    @homeroom_teacher = @teacher
    @course.update!(homeroom_course: true)
    @homeroom_course = @course

    @subject_course_title = "Math"
    course_with_teacher(
      active_course: 1,
      active_enrollment: 1,
      user: @homeroom_teacher,
      course_name: @subject_course_title
    )
    @subject_course = @course
  end

  def admin_setup
    feature_setup
    teacher_setup
    account_admin_user(:account => @account)
  end

  def create_assignment(course, assignment_title, description, points_possible)
    course.assignments.create!(
      title: assignment_title,
      description: description,
      points_possible: points_possible,
      submission_types: 'online_text_entry',
      workflow_state: 'published'
    )
  end

  def create_and_submit_assignment(course, assignment_title, description, points_possible)
    assignment = create_assignment(course, assignment_title, description, points_possible)
    assignment.submit_homework(@student, {submission_type: "online_text_entry", body: "Here it is"})
    assignment
  end

  def create_course_module(workflow_state = 'active')
    @module_title = "Course Module"
    @course_module = @subject_course.context_modules.create!(:name => @module_title, :workflow_state => workflow_state)
    @module_assignment_title = "General Assignment"
    assignment = create_dated_assignment(@subject_course, @module_assignment_title, 1.day.from_now)
    @course_module.add_item(:id => assignment.id, :type => 'assignment')
  end

  def create_grading_standard(course)
    course.grading_standards.create!(
      title: "Fun Grading Standard",
      standard_data: {
        "scheme_0" => { name: "Awesome", value: "90" },
        "scheme_1" => { name: "Fabulous", value: "80" },
        "scheme_2" => { name: "You got this", value: "70" },
        "scheme_3" => { name: "See me", value: "0" }
      }
    )
  end

  def hex_value_for_color(element)
    '#' + ColorCommon.rgba_to_hex(element.style('background-color'))
  end
end
