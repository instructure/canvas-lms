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

require_relative "../../common"
require_relative "../../helpers/color_common"

module K5DashboardPageObject
  include ColorCommon

  #------------------------- Selectors --------------------------

  def account_name_selector
    "[placeholder='Begin typing to search']"
  end

  def add_paired_student_selector
    "[data-testid='add-student-btn']"
  end

  def announcement_button_selector
    "//a[*//. = 'Announcement']"
  end

  def announcement_content_text_selector(content_text)
    "div:contains('#{content_text}')"
  end

  def announcement_edit_button_selector
    "a[cursor='pointer']"
  end

  def announcement_on_card_xpath_selector(announcement_title)
    "//div[@class = 'ic-DashboardCard']//span[text() = '#{announcement_title}']"
  end

  def announcement_title_xpath_selector(announcement_title)
    "//h3/a[text() = '#{announcement_title}']|//h3[text() = '#{announcement_title}']"
  end

  def assignment_edit_button_selector
    ".edit_assignment_link"
  end

  def assignment_page_title_selector
    "h1"
  end

  def assignment_url_selector(course_id, assignment_id)
    "a[href = '/courses/#{course_id}/assignments/#{assignment_id}']"
  end

  def classic_dashboard_header_selector
    "h1:contains('Dashboard')"
  end

  def close_pairing_modal_selector
    "[data-testid='close-modal']"
  end

  def course_card_selector(course_title)
    "div[title='#{course_title}']"
  end

  def course_color_preview_selector
    "[data-testid='course-color-preview']"
  end

  def course_dashboard_title_selector
    "h1"
  end

  def course_homeroom_option_selector(option_text)
    "#course_homeroom_course_id option:contains('#{option_text}')"
  end

  def course_name_input_selector
    "[placeholder='Name...']"
  end

  def course_navigation_tray_selector
    "[aria-label='Course Navigation Tray']"
  end

  def course_nav_tray_close_selector
    "//button[.//*[. = 'Close']]"
  end

  def dashboard_card_selector
    "[data-testid='k5-dashboard-card-hero']"
  end

  def dashboard_header_selector
    "[data-testid='k5-course-header-hero']"
  end

  def dashboard_options_button_selector
    "[data-testid = 'k5-dashboard-options']"
  end

  def dashboard_card_specific_subject_selector(subject)
    "[data-testid='k5-dashboard-card'][aria-label='#{subject}'"
  end

  def empty_dashboard_selector
    "[data-testid = 'empty-dash-panda']:visible"
  end

  def empty_groups_image_selector
    "[data-testid='empty-groups-image']"
  end

  def empty_subject_home_selector
    "[data-testid = 'empty-home-panda']:visible"
  end

  def enable_homeroom_checkbox_selector
    "#course_homeroom_course"
  end

  def front_page_info_selector
    "#course_home_content .user_content"
  end

  def grades_tab_selector
    "#tab-tab-grades"
  end

  def group_management_button_selector(button_type)
    "button:contains('#{button_type}')"
  end

  def groups_tab_selector
    "#tab-tab-groups"
  end

  def group_titles_selector
    ".student-group-header h2"
  end

  def home_tab_selector
    "#tab-tab-home"
  end

  def homeroom_course_title_selector(title)
    "h2:contains('#{title}')"
  end

  def homeroom_select_selector
    "[data-testid='homeroom-select']"
  end

  def homeroom_tab_selector
    "#tab-tab-homeroom"
  end

  def items_due_selector(subject_title)
    "//*[@aria-label = '#{subject_title}']//*[@data-testid = 'number-due-today']"
  end

  def items_missing_selector(subject_title)
    "//*[@aria-label = '#{subject_title}']//*[@data-testid = 'number-missing']"
  end

  def k5_tablist_selector
    "[role='tablist']"
  end

  def k5_header_selector
    ".ic-Dashboard-tabs"
  end

  def leave_student_view_selector
    "#masquerade_bar .leave_student_view"
  end

  def manage_button_selector
    "[data-testid = 'manage-button']"
  end

  def manage_groups_button_selector
    "#k5-manage-groups-btn"
  end

  def manage_home_button_selector
    "[data-testid = 'manage-home-button'"
  end

  def missing_item_href_selector(course_id, assignment_id)
    "//*[contains(@href, '/courses/#{course_id}/assignments/#{assignment_id}')]"
  end

  def modules_tab_selector
    "#tab-tab-modules"
  end

  def navigation_item_selector
    ".navitem"
  end

  def new_course_button_selector
    "[data-testid='new-course-button']"
  end

  def new_course_modal_cancel_selector
    "//button[.//*[. = 'Cancel']]"
  end

  def new_course_modal_close_button_selector
    "[data-testid='instui-modal-close']"
  end

  def new_course_modal_create_selector
    "//button[.//*[. = 'Create']]"
  end

  def new_course_modal_selector
    "[aria-label='Create Subject']"
  end

  def next_announcement_button_selector
    "button:contains('Next announcement')"
  end

  def no_recent_announcements_selector
    "[data-testid='no-recent-announcements']"
  end

  def nothing_due_selector(subject_course_title)
    "//*[@aria-label = '#{subject_course_title}']//*[text() = 'Nothing due today']"
  end

  def observed_student_label_selector
    "[data-testid='observed-student-label']"
  end

  def observed_student_dropdown_selector
    "[data-testid='observed-student-dropdown']"
  end

  def pairing_code_input_selector
    "[placeholder='Pairing code']"
  end

  def pairing_modal_selector
    "[aria-label='Pair with student']"
  end

  def pink_color_button_selector
    "//button[contains(@id,'DF6B91')]"
  end

  def planner_assignment_header_selector
    ".Grouping-styles__overlay"
  end

  def previous_announcement_button_selector
    "button:contains('Previous announcement')"
  end

  def resources_tab_selector
    "#tab-tab-resources"
  end

  def selected_color_input_selector
    "[name='course[course_color]']"
  end

  def schedule_tab_selector
    "#tab-tab-schedule"
  end

  def student_view_button_selector
    "#student-view-btn"
  end

  def subject_link_selector(subject_title)
    "//a[div[@title = '#{subject_title}']]"
  end

  def sync_enrollments_checkbox_selector
    "input + label:contains('Sync enrollments and subject start/end dates from homeroom')"
  end

  def welcome_title_selector
    "span:contains('Welcome,')"
  end

  #------------------------- Elements --------------------------

  def account_name_element
    f(account_name_selector)
  end

  def add_paired_student
    f(add_paired_student_selector)
  end

  def announcement_button
    fxpath(announcement_button_selector)
  end

  def announcement_content_text(content_text)
    fj(announcement_content_text_selector(content_text))
  end

  def announcement_edit_pencil
    f(announcement_edit_button_selector)
  end

  def announcement_title(announcement_title)
    wait_for(method: nil, timeout: 1) do
      fxpath(announcement_title_xpath_selector(announcement_title))
    end
  end

  def assignment_edit_button
    f(assignment_edit_button_selector)
  end

  def assignments_link
    fln("Assignments")
  end

  def assignment_page_title
    f(assignment_page_title_selector)
  end

  def assignment_url(assignment_title)
    fj(assignment_url_selector(assignment_title))
  end

  def classic_dashboard_header
    fj(classic_dashboard_header_selector)
  end

  def close_pairing_modal
    f(close_pairing_modal_selector)
  end

  def course_card(course_title)
    f("div[title='#{course_title}']")
  end

  def course_card_announcement(course_title)
    fxpath(announcement_on_card_xpath_selector(course_title))
  end

  def course_color_preview
    f(course_color_preview_selector)
  end

  def course_dashboard_title
    f(course_dashboard_title_selector)
  end

  def course_homeroom_option(option_text)
    fj(course_homeroom_option_selector(option_text))
  end

  def course_name_input
    f(course_name_input_selector)
  end

  def course_navigation_tray
    f(course_navigation_tray_selector)
  end

  def course_nav_tray_close
    fxpath(course_nav_tray_close_selector)
  end

  def dashboard_card
    f(dashboard_card_selector)
  end

  def dashboard_card_specific_subject(subject)
    f(dashboard_card_specific_subject_selector(subject))
  end

  def dashboard_header
    f(dashboard_header_selector)
  end

  def dashboard_options
    INSTUI_Menu_options(dashboard_options_button_selector)
  end

  def dashboard_options_button
    f(dashboard_options_button_selector)
  end

  def empty_dashboard
    fj(empty_dashboard_selector)
  end

  def empty_groups_image
    f(empty_groups_image_selector)
  end

  def empty_subject_home
    fj(empty_subject_home_selector)
  end

  def enable_homeroom_checkbox
    f(enable_homeroom_checkbox_selector)
  end

  def front_page_info
    f(front_page_info_selector)
  end

  def grades_tab
    f(grades_tab_selector)
  end

  def group_management_buttons(button_text)
    ffj(group_management_button_selector(button_text))
  end

  def groups_tab
    f(groups_tab_selector)
  end

  def group_titles
    ff(group_titles_selector)
  end

  def home_tab
    f(home_tab_selector)
  end

  def homeroom_course_title(title)
    fj(homeroom_course_title_selector(title))
  end

  def homeroom_course_title_link(title)
    fln(title)
  end

  def homeroom_select
    f(homeroom_select_selector)
  end

  def homeroom_tab
    f(homeroom_tab_selector)
  end

  def k5_tablist
    f(k5_tablist_selector)
  end

  def k5_header
    f(k5_header_selector)
  end

  def leave_student_view
    f(leave_student_view_selector)
  end

  def manage_button
    f(manage_button_selector)
  end

  def manage_groups_button
    f(manage_groups_button_selector)
  end

  def manage_home_button
    f(manage_home_button_selector)
  end

  def modules_tab
    f(modules_tab_selector)
  end

  def navigation_items
    ff(navigation_item_selector)
  end

  def new_course_button
    f(new_course_button_selector)
  end

  def new_course_modal
    f(new_course_modal_selector)
  end

  def new_course_modal_cancel
    fxpath(new_course_modal_cancel_selector)
  end

  def new_course_modal_close_button
    f(new_course_modal_close_button_selector)
  end

  def new_course_modal_create
    fxpath(new_course_modal_create_selector)
  end

  def next_announcement_button
    ffj(next_announcement_button_selector)
  end

  def no_recent_announcements
    f(no_recent_announcements_selector)
  end

  def nothing_due(subject_course_title)
    fxpath(nothing_due_selector(subject_course_title))
  end

  def observed_student_label
    f(observed_student_label_selector)
  end

  def observed_student_dropdown
    f(observed_student_dropdown_selector)
  end

  def pairing_code_input
    f(pairing_code_input_selector)
  end

  def pairing_modal
    f(pairing_modal_selector)
  end

  def pink_color_button
    fxpath(pink_color_button_selector)
  end

  def previous_announcement_button
    ffj(previous_announcement_button_selector)
  end

  def resources_tab
    f(resources_tab_selector)
  end

  def selected_color_input
    f(selected_color_input_selector)
  end

  def schedule_tab
    f(schedule_tab_selector)
  end

  def student_view_button
    f(student_view_button_selector)
  end

  def subject_items_due(subject_title)
    fxpath(items_due_selector(subject_title))
  end

  def subject_items_missing(subject_title)
    fxpath(items_missing_selector(subject_title))
  end

  def subject_title_link(subject_title)
    fxpath(subject_link_selector(subject_title))
  end

  def sync_enrollments_checkbox
    fj(sync_enrollments_checkbox_selector)
  end

  def welcome_title
    fj(welcome_title_selector)
  end

  #----------------------- Actions & Methods -------------------------
  #----------------------- Click Items -------------------------------

  def click_announcement_button
    announcement_button.click
  end

  def click_announcement_edit_pencil
    announcement_edit_pencil.click
  end

  def click_announcement_title(announcement_title)
    announcement_title(announcement_title).click
  end

  def click_assignments_link
    assignments_link.click
  end

  def click_dashboard_card
    dashboard_card.click
  end

  def click_dashboard_options_button
    dashboard_options_button.click
  end

  def click_close_pairing_button
    close_pairing_modal.click
    wait_for_ajaximations
  end

  def click_duetoday_subject_item(title)
    subject_items_due(title).click
  end

  def click_group_join_button(button_selector)
    button_selector.click
  end

  def click_homeroom_course_title(course_title)
    homeroom_course_title_link(course_title).click
  end

  def click_manage_button
    manage_button.click
    wait_for(method: nil, timeout: 2) { course_navigation_tray }
  end

  def click_manage_groups_button
    manage_groups_button.click
  end

  def click_missing_subject_item(title)
    subject_items_missing(title).click
  end

  def click_nav_tray_close
    course_nav_tray_close.click
    wait_for_ajaximations
  end

  def click_new_course_button
    new_course_button.click
  end

  def click_new_course_cancel
    new_course_modal_cancel.click
  end

  def click_new_course_close_button
    new_course_modal_close_button.click
  end

  def click_new_course_create
    new_course_modal_create.click
  end

  def click_next_announcement_button(button_number)
    next_announcement_button[button_number].click
  end

  def click_observed_student_option(student_name)
    click_option(observed_student_dropdown_selector, student_name)
  end

  def click_pairing_button
    add_paired_student.click
    wait_for_ajaximations
  end

  def click_pink_color_button
    pink_color_button.click
  end

  def click_previous_announcement_button(button_number)
    previous_announcement_button[button_number].click
  end

  def click_student_view_button
    student_view_button.click
  end

  def click_sync_enrollments_checkbox
    sync_enrollments_checkbox.click
  end

  def check_enable_homeroom_checkbox
    enable_homeroom_checkbox.click
  end

  def navigate_to_subject(subject_title)
    subject_title_link(subject_title).click
  end

  def select_account_from_list(account_name)
    click_option(account_name_selector, account_name)
  end

  def select_grades_tab
    grades_tab.click
  end

  def select_home_tab
    home_tab.click
  end

  def select_homeroom_tab
    homeroom_tab.click
  end

  def select_resources_tab
    resources_tab.click
  end

  def select_schedule_tab
    schedule_tab.click
  end

  #------------------------------Retrieve Text----------------------#

  def group_titles_text_list
    group_titles.map(&:text)
  end

  def retrieve_title_text
    course_dashboard_title.text
  end

  #----------------------------Element Management---------------------#

  def announcement_button_exists?
    element_exists?(announcement_button_selector, true)
  end

  def announcement_title_exists?(announcement_heading)
    element_exists?(announcement_title_xpath_selector(announcement_heading), true)
  end

  def assignment_link_exists?(course_id, assignment_id)
    element_exists?(assignment_url_selector(course_id, assignment_id))
  end

  def course_navigation_tray_exists?
    element_exists?(course_navigation_tray_selector)
  end

  def enter_account_search_data(search_term)
    replace_content(account_name_element, search_term)
    driver.action.send_keys(:enter).perform
  end

  def fill_out_course_modal(account, course_name)
    enter_account_search_data(account.name[0...3])
    select_account_from_list(account.name)
    enter_course_name(course_name)
  end

  def enter_course_name(course_name)
    replace_content(course_name_input, course_name)
    driver.action.send_keys(:enter).perform
  end

  def input_color_hex_value(hex_value)
    selected_color_input.send_keys(hex_value)
  end

  def groups_tab_exists?
    element_exists?(groups_tab_selector)
  end

  def modules_tab_exists?
    element_exists?(modules_tab_selector)
  end

  def new_course_modal_exists?
    element_exists?(new_course_modal_selector)
  end
end
