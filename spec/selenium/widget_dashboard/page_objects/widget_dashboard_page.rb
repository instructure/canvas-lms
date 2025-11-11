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

module WidgetDashboardPage
  #------------------------------ Selectors -----------------------------
  def announcement_filter_select
    "[data-testid='announcement-filter-select']"
  end

  def announcement_item_prefix_selector
    "[data-testid*='announcement-item-']"
  end

  def announcement_item_selector(item_id)
    "[data-testid='announcement-item-#{item_id}']"
  end

  def announcement_item_title_selector(item_id)
    "[data-testid='announcement-item-#{item_id}'] a[href]"
  end

  def announcement_item_mark_read_selector(item_id)
    "[data-testid='mark-read-#{item_id}']"
  end

  def announcement_item_mark_unread_selector(item_id)
    "[data-testid='mark-unread-#{item_id}']"
  end

  def announcement_item_link_selector(item_id)
    "[data-testid='read-more-#{item_id}']"
  end

  def widget_pagination_container_selector(widget)
    "nav[aria-label='#{widget} pagination']"
  end

  def widget_pagination_button_selector(widget, page_number)
    "#{widget_pagination_container_selector(widget)} button:contains('#{page_number}')"
  end

  def widget_pagination_next_button_selector(widget)
    "#{widget_pagination_container_selector(widget)} button[data-direction='next']"
  end

  def widget_pagination_prev_button_selector(widget)
    "#{widget_pagination_container_selector(widget)} button[data-direction='prev']"
  end

  def people_widget_selector
    "[data-testid='widget-people-widget']"
  end

  def message_instructor_button_selector(account_id, course_id)
    "[data-testid='message-button-#{account_id}-#{course_id}']"
  end

  def send_message_to_modal_selector(teacher_name)
    "span[role = 'dialog'][aria-label='Send Message to #{teacher_name}']"
  end

  def message_modal_subject_input_selector
    "span[role = 'dialog'] input[type='text']"
  end

  def message_modal_body_textarea_selector
    "span[role = 'dialog'] textarea"
  end

  def message_modal_send_button_selector
    "button[data-testid='message-students-submit']"
  end

  def message_modal_alert_selector
    ".MessageStudents__Alert"
  end

  def hide_all_grades_checkbox_selector
    "[data-testid='hide-all-grades-checkbox']"
  end

  def show_all_grades_checkbox_selector
    "[data-testid='show-all-grades-checkbox']"
  end

  def hide_single_grade_button_selector(course_id)
    "[data-testid='hide-single-grade-button-#{course_id}']"
  end

  def show_single_grade_button_selector(course_id)
    "[data-testid='show-single-grade-button-#{course_id}']"
  end

  def course_gradebook_link_selector(course_id)
    "[data-testid='course-#{course_id}-gradebook-link']"
  end

  def course_grade_text_selector(course_id)
    "[data-testid='course-#{course_id}-grade']"
  end

  def course_work_summary_stats_selector(label)
    "[data-testid='statistics-card-#{label}']"
  end

  def course_work_course_filter_select_selector
    "[data-testid='course-filter-select']"
  end

  def course_work_date_filter_select_selector
    "[data-testid='date-filter-select']"
  end

  def course_work_item_selector(item_id)
    "[data-testid='listed-course-work-item-#{item_id}']"
  end

  def course_work_item_link_selector(item_id)
    "[data-testid='course-work-item-link-#{item_id}']"
  end

  def course_work_item_pill_selector(status_label, item_id)
    "[data-testid='#{status_label}-status-pill-#{item_id}']"
  end

  def no_course_work_message_selector
    "[data-testid='no-course-work-message']"
  end

  def no_announcements_message_selector
    "[data-testid='no-announcements-message']"
  end

  def no_instructors_message_selector
    "[data-testid='no-instructors-message']"
  end

  def no_enrolled_courses_message_selector
    "[data-testid='no-courses-message']"
  end

  def enrollment_invitation_selector
    "[data-testid='enrollment-invitation']"
  end

  def enrollment_invitation_accept_button_selector
    "[data-testid='enrollment-invitation'] button:contains('Accept')"
  end

  def enrollment_invitation_decline_button_selector
    "[data-testid='enrollment-invitation'] button:contains('Decline')"
  end

  def all_enrollment_invitations_selector
    "[data-testid='enrollment-invitation']"
  end

  def observed_student_dropdown_selector
    "[data-testid='observed-student-dropdown']"
  end
  #------------------------------ Elements ------------------------------

  def announcement_filter
    f(announcement_filter_select)
  end

  def all_announcement_items
    ff(announcement_item_prefix_selector)
  end

  def announcement_item(item_id)
    f(announcement_item_selector(item_id))
  end

  def announcement_item_title(item_id)
    f(announcement_item_title_selector(item_id))
  end

  def announcement_item_mark_read(item_id)
    f(announcement_item_mark_read_selector(item_id))
  end

  def announcement_item_mark_unread(item_id)
    f(announcement_item_mark_unread_selector(item_id))
  end

  def announcement_item_link(item_id)
    f(announcement_item_link_selector(item_id))
  end

  def widget_pagination_button(widget, page_number)
    fj(widget_pagination_button_selector(widget, page_number))
  end

  def widget_pagination_next_button(widget)
    f(widget_pagination_next_button_selector(widget))
  end

  def widget_pagination_prev_button(widget)
    f(widget_pagination_prev_button_selector(widget))
  end

  def people_widget
    f(people_widget_selector)
  end

  def all_message_buttons
    ff("[data-testid*='message-button-']")
  end

  def message_instructor_button(account_id, course_id)
    f(message_instructor_button_selector(account_id, course_id))
  end

  def send_message_to_modal(teacher_name)
    f(send_message_to_modal_selector(teacher_name))
  end

  def message_modal_subject_input
    f(message_modal_subject_input_selector)
  end

  def message_modal_body_textarea
    f(message_modal_body_textarea_selector)
  end

  def message_modal_send_button
    f(message_modal_send_button_selector)
  end

  def message_modal_alert
    f(message_modal_alert_selector)
  end

  def hide_all_grades_checkbox
    f(hide_all_grades_checkbox_selector)
  end

  def show_all_grades_checkbox
    f(show_all_grades_checkbox_selector)
  end

  def hide_single_grade_button(course_id)
    f(hide_single_grade_button_selector(course_id))
  end

  def show_single_grade_button(course_id)
    f(show_single_grade_button_selector(course_id))
  end

  def course_gradebook_link(course_id)
    f(course_gradebook_link_selector(course_id))
  end

  def course_grade_text(course_id)
    f(course_grade_text_selector(course_id))
  end

  def all_course_grade_items
    ff("[data-testid*='hide-single-grade-button-']")
  end

  def course_work_summary_stats(label)
    f(course_work_summary_stats_selector(label))
  end

  def all_course_work_items
    ff("[data-testid*='listed-course-work-item-']")
  end

  def course_work_item(item_id)
    f(course_work_item_selector(item_id))
  end

  def course_work_item_link(item_id)
    f(course_work_item_link_selector(item_id))
  end

  def course_work_item_pill(status_label, item_id)
    f(course_work_item_pill_selector(status_label, item_id))
  end

  def no_course_work_message
    f(no_course_work_message_selector)
  end

  def no_announcements_message
    f(no_announcements_message_selector)
  end

  def no_instructors_message
    f(no_instructors_message_selector)
  end

  def no_enrolled_courses_message
    f(no_enrolled_courses_message_selector)
  end

  def enrollment_invitation
    f(enrollment_invitation_selector)
  end

  def all_enrollment_invitations
    ff(all_enrollment_invitations_selector)
  end

  def enrollment_invitation_accept_button
    fj(enrollment_invitation_accept_button_selector)
  end

  def enrollment_invitation_decline_button
    fj(enrollment_invitation_decline_button_selector)
  end

  def observed_student_dropdown
    f(observed_student_dropdown_selector)
  end

  #------------------------------ Actions -------------------------------

  def filter_announcements_list_by(status)
    announcement_filter.click
    click_INSTUI_Select_option(announcement_filter_select, status)
  end

  def filter_course_work_by(filter_type, filter_value)
    case filter_type
    when :course
      click_INSTUI_Select_option(course_work_course_filter_select_selector, filter_value)
    when :date
      click_INSTUI_Select_option(course_work_date_filter_select_selector, filter_value)
    end
    wait_for_ajaximations
  end

  def select_observed_student(student_name)
    expect(observed_student_dropdown).to be_displayed
    click_INSTUI_Select_option(observed_student_dropdown_selector, student_name)
    wait_for_ajaximations
  end

  def go_to_dashboard
    get "/"
    wait_for_ajaximations
  end
end
