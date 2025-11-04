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

  def widget_pagination_button_selector(widget, page_number)
    "[data-testid='widget-#{widget}-widget'] [data-testid='pagination-container'] button:contains('#{page_number}')"
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

  def dashboard_student_setup
    @course1 = course_factory(active_all: true, course_name: "Course 1")
    @course2 = course_factory(active_all: true, course_name: "Course 2")

    @teacher1 = user_factory(active_all: true, name: "Nancy Smith")
    @teacher2 = user_factory(active_all: true, name: "John Doe")
    @student = user_factory(active_all: true, name: "Jane Brown")

    @course1.enroll_teacher(@teacher1, enrollment_state: :active)
    @course2.enroll_teacher(@teacher2, enrollment_state: :active)
    @course1.enroll_student(@student, enrollment_state: :active)
    @course2.enroll_student(@student, enrollment_state: :active)
  end

  def set_widget_dashboard_flag(feature_status: true)
    feature_status ? @course1.root_account.enable_feature!(:widget_dashboard) : @course1.root_account.disable_feature!(:widget_dashboard)
  end

  def dashboard_announcement_setup
    @announcement1 = @course1.announcements.create!(title: "Course 1 - Announcement title 1", message: "Announcement message 1")
    @announcement2 = @course2.announcements.create!(title: "Course 2 - Announcement title 2", message: "Announcement message 2")
    @announcement3 = @course1.announcements.create!(title: "Course 1 - Announcement title 3", message: "Announcement message 3")
    @announcement4 = @course2.announcements.create!(title: "Course 2 - Announcement title 4", message: "Announcement message 4")
    @announcement5 = @course1.announcements.create!(title: "Course 1 - Announcement title 5", message: "Announcement message 5")
    @announcement6 = @course2.announcements.create!(title: "Course 2 - Announcement title 6", message: "Announcement message 6")
    @announcement7 = @course1.announcements.create!(title: "Course 1 - Announcement title 7", message: "Announcement message 7. This is a longer message to test the read more link functionality on the announcements widget. This message should be long enough to be truncated.")

    @announcement6.discussion_topic_participants.find_by(user: @student)&.update!(workflow_state: "read")
    @announcement5.discussion_topic_participants.find_by(user: @student)&.update!(workflow_state: "read")
  end

  def dashboard_people_setup
    @ta1 = course_with_ta(name: "Alice Davis", course: @course1, active_all: true).user
    @ta2 = course_with_ta(name: "Bob Johnson", course: @course2, active_all: true).user
  end

  def dashboard_course_assignment_setup
    @due_graded_discussion = @course1.assignments.create!(name: "Course 1: due_graded_discussion", points_possible: "10", due_at: 6.days.from_now, submission_types: "discussion_topic")
    @due_assignment = @course1.assignments.create!(name: "Course 1: due_assignment", points_possible: "10", due_at: 1.day.from_now, submission_types: "online_text_entry")
    @due_quiz = @course1.assignments.create!(title: "Course 1: due_quiz", points_possible: "10", due_at: 13.days.from_now, submission_types: "online_quiz")

    @missing_graded_discussion = @course1.assignments.create!(name: "Course 1: missing_graded_discussion", points_possible: "10", due_at: 2.days.ago, submission_types: "discussion_topic")
    @missing_assignment = @course2.assignments.create!(name: "Course 2: missing_assignment", points_possible: "10", due_at: 3.days.ago, submission_types: "online_text_entry")
    @missing_quiz = @course2.assignments.create!(title: "Course 2: missing_quiz", points_possible: "10", due_at: 4.days.ago, submission_types: "online_quiz")

    @graded_discussion = @course1.assignments.create!(name: "Course 1: graded_discussion", points_possible: "10", due_at: 5.days.ago, submission_types: "discussion_topic")
    @graded_assignment = @course2.assignments.create!(name: "Course 2: graded_assignment", points_possible: "10", due_at: 3.days.ago, submission_types: "online_text_entry")

    @submitted_discussion = @course2.assignments.create!(name: "Course 2: submitted_discussion", points_possible: "10", due_at: 2.days.ago, submission_types: "discussion_topic")
    @submitted_assignment = @course1.assignments.create!(name: "Course 1: submitted_assignment", points_possible: "10", due_at: 1.day.from_now, submission_types: "online_text_entry")
  end

  def dashboard_course_submission_setup
    @submitted_assignment.submit_homework(@student, submission_type: "online_text_entry")
    @submitted_discussion.submit_homework(@student, submission_type: "discussion_topic")

    @graded_assignment.submit_homework(@student, submission_type: "online_text_entry")
    @graded_discussion.submit_homework(@student, submission_type: "discussion_topic")

    @graded_quiz = @course1.quizzes.create!(title: "submitted_quiz", due_at: 1.day.from_now)
    @graded_quiz.quiz_questions.create!(question_data: { question_type: "true_false_question", points_possible: 10 })
    @graded_quiz.generate_quiz_data
    @graded_quiz.workflow_state = "available"
    @graded_quiz.save!
    qs = @graded_quiz.generate_submission(@student)
    qs.submission_data
    Quizzes::SubmissionGrader.new(qs).grade_submission
  end

  def dashboard_course_grade_setup
    @graded_assignment.grade_student(@student, grade: "8", grader: @teacher2)
    @graded_discussion.grade_student(@student, grade: "9", grader: @teacher1)
  end

  def observed_student_setup
    @student2 = user_factory(active_all: true, name: "student2")
    @course1.enroll_student(@student2, enrollment_state: :active)
    @course2.enroll_student(@student2, enrollment_state: :active)

    @submitted_discussion.submit_homework(@student2, submission_type: "discussion_topic")
    @graded_assignment.submit_homework(@student2, submission_type: "online_text_entry")
    @graded_assignment.grade_student(@student2, grade: "10", grader: @teacher2)
  end

  def observer_setup
    @observer = user_factory(name: "Observer", active_all: true)

    @course1.enroll_user(@observer, "ObserverEnrollment", { allow_multiple_enrollments: true, associated_user_id: @student })
    @course2.enroll_user(@observer, "ObserverEnrollment", { allow_multiple_enrollments: true, associated_user_id: @student2 })
  end

  def dashboard_pending_enrollment_setup
    @course3 = course_factory(active_all: true, course_name: "Test Course")

    @assignment_pending_course = @course3.assignments.create!(name: "Course 3: due_graded_discussion", points_possible: "10", due_at: 2.days.from_now, submission_types: "discussion_topic")
    @course3.enroll_teacher(@teacher1, enrollment_state: :active)
    @announcement_pending_course = @course3.announcements.create!(title: "Course 3 - Announcement", message: "Announcement message for pending enrollment course")
  end

  def dashboard_inactive_courses_setup
    @student_w_inactive = user_factory(active_all: true, name: "Student-W Inactive-courses")

    @past_course = course_factory(active_all: true, course_name: "Past Course")
    @past_course.enroll_student(@student_w_inactive, enrollment_state: "active")
    @past_course.update!(conclude_at: 1.week.ago, restrict_enrollments_to_course_dates: true)

    @concluded_course = course_factory(active_all: true, course_name: "Concluded Course")
    student_enroll1 = @concluded_course.enroll_student(@student_w_inactive, enrollment_state: "active")
    student_enroll1.workflow_state = "completed"
    student_enroll1.save!

    @unpublished_course = course_factory(active_all: true, course_name: "Unpublished Course")
    student_enroll2 = @unpublished_course.enroll_student(@student_w_inactive, enrollment_state: "active")
    student_enroll2.workflow_state = "creation_pending"
    student_enroll2.save!
  end

  def observer_w_inactive_courses_setup
    @observer = user_factory(name: "Observer2", active_all: true)
    @past_course.enroll_user(@observer, "ObserverEnrollment", enrollment_state: "active", associated_user_id: @student_w_inactive)
    observer_enroll2 = @concluded_course.enroll_user(@observer, "ObserverEnrollment", enrollment_state: "active", associated_user_id: @student_w_inactive)
    observer_enroll2.workflow_state = "completed"
    observer_enroll2.save!

    observer_enroll2 = @unpublished_course.enroll_user(@observer, "ObserverEnrollment", enrollment_state: "active", associated_user_id: @student_w_inactive)
    observer_enroll2.workflow_state = "creation_pending"
    observer_enroll2.save!
    @course1.enroll_user(@observer, "ObserverEnrollment", { allow_multiple_enrollments: true, associated_user_id: @student })
    @course1.enroll_user(@observer, "ObserverEnrollment", { allow_multiple_enrollments: true, associated_user_id: @student_w_inactive })
  end

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
