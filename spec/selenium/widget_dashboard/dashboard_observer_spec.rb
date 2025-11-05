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

require_relative "page_objects/widget_dashboard_page"
require_relative "../helpers/student_dashboard_common"

describe "Student dashboard as observer", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include WidgetDashboardPage
  include StudentDashboardCommon

  before :once do
    dashboard_student_setup # Creates courses and a student enrolled in
    dashboard_course_assignment_setup
    dashboard_course_submission_setup
    dashboard_course_grade_setup
    observed_student_setup # created second student with submissions in course2
    observer_setup
    set_widget_dashboard_flag(feature_status: true)
  end

  before do
    user_session(@observer)
  end

  context "Course work widget as observer" do
    it "filter observed course items by dues" do
      go_to_dashboard
      select_observed_student(@student.name)

      expect(all_course_work_items.size).to eq(1)
      expect(course_work_summary_stats("Due").text).to eq("1\nDue")
      expect(course_work_item(@due_assignment.id)).to be_displayed

      filter_course_work_by(:date, "Next 14 days")
      expect(all_course_work_items.size).to eq(3)
      expect(course_work_summary_stats("Due").text).to eq("3\nDue")
      expect(course_work_item(@due_graded_discussion.id)).to be_displayed
      expect(course_work_item(@due_quiz.id)).to be_displayed

      select_observed_student(@student2.name)
      expect(course_work_summary_stats("Due").text).to eq("0\nDue") # dashboard updates after switching views
    end

    it "filter observed course items by missing" do
      go_to_dashboard
      select_observed_student(@student.name)
      expect(course_work_summary_stats("Missing")).to be_displayed

      filter_course_work_by(:date, "Missing")
      expect(all_course_work_items.size).to eq(1)
      expect(course_work_summary_stats("Missing").text).to eq("1\nMissing")
      expect(course_work_item(@missing_graded_discussion.id)).to be_displayed

      select_observed_student(@student2.name)
      expect(course_work_summary_stats("Missing").text).to eq("2\nMissing") # dashboard updates after switching views
      filter_course_work_by(:date, "Missing")
      expect(all_course_work_items.size).to eq(2)
      expect(course_work_item(@missing_assignment.id)).to be_displayed
      expect(course_work_item(@missing_quiz.id)).to be_displayed
    end

    it "filter observed course items by submitted" do
      go_to_dashboard
      select_observed_student(@student.name)
      expect(course_work_summary_stats("Submitted")).to be_displayed

      filter_course_work_by(:date, "Submitted")
      expect(all_course_work_items.size).to eq(3)
      expect(course_work_summary_stats("Submitted").text).to eq("3\nSubmitted")

      expect(course_work_item(@submitted_assignment.id)).to be_displayed
      expect(course_work_item(@graded_discussion.id)).to be_displayed

      select_observed_student(@student2.name)
      expect(course_work_summary_stats("Submitted").text).to eq("2\nSubmitted") # dashboard updates after switching views
      filter_course_work_by(:date, "Submitted")
      expect(all_course_work_items.size).to eq(2)
      expect(course_work_item(@submitted_discussion.id)).to be_displayed
      expect(course_work_item(@graded_assignment.id)).to be_displayed
    end

    it "filter observed course items by course" do
      @course2.enroll_user(@observer, "ObserverEnrollment", { allow_multiple_enrollments: true, associated_user_id: @student })
      @course1.enroll_student(@student2, enrollment_state: :active)
      @course1.enroll_user(@observer, "ObserverEnrollment", { allow_multiple_enrollments: true, associated_user_id: @student2 })

      go_to_dashboard
      select_observed_student(@student.name)
      expect(course_work_summary_stats("Due")).to be_displayed

      filter_course_work_by(:course, @course2.name)
      expect(course_work_summary_stats("Submitted").text).to eq("2\nSubmitted")
      filter_course_work_by(:course, @course1.name)
      expect(course_work_summary_stats("Submitted").text).to eq("3\nSubmitted")

      select_observed_student(@student2.name)
      filter_course_work_by(:course, @course2.name)
      expect(course_work_summary_stats("Submitted").text).to eq("2\nSubmitted")
      filter_course_work_by(:course, @course1.name)
      expect(course_work_summary_stats("Submitted").text).to eq("0\nSubmitted")
    end

    it "navigates to observed course work" do
      go_to_dashboard
      select_observed_student(@student.name)

      expect(course_work_item_link(@due_assignment.id)).to be_displayed
      course_work_item_link(@due_assignment.id).click
      expect(driver.current_url).to include("/courses/#{@course1.id}/assignments/#{@due_assignment.id}")

      go_to_dashboard
      select_observed_student(@student2.name)
      filter_course_work_by(:date, "Submitted")
      expect(course_work_item(@graded_assignment.id)).to be_displayed
      course_work_item_link(@graded_assignment.id).click
      expect(driver.current_url).to include("/courses/#{@course2.id}/assignments/#{@graded_assignment.id}")
    end
  end

  context "Course grades widget as observer" do
    it "view grades only for observed courses and student" do
      go_to_dashboard

      select_observed_student(@student.name)
      expect(hide_single_grade_button(@course1.id)).to be_displayed
      expect(element_exists?(hide_single_grade_button_selector(@course2.id))).to be_falsey

      select_observed_student(@student2.name)
      expect(hide_single_grade_button(@course2.id)).to be_displayed
      expect(element_exists?(hide_single_grade_button_selector(@course1.id))).to be_falsey
    end

    it "navigates to observed courses gradebook as observer" do
      go_to_dashboard

      select_observed_student(@student.name)
      expect(course_gradebook_link(@course1.id)).to be_displayed
      course_gradebook_link(@course1.id).click
      expect(driver.current_url).to include("/courses/#{@course1.id}/grades")

      go_to_dashboard

      select_observed_student(@student2.name)
      expect(course_gradebook_link(@course2.id)).to be_displayed
      course_gradebook_link(@course2.id).click
      expect(driver.current_url).to include("/courses/#{@course2.id}/grades")
    end
  end

  context "Announcements widget as observer" do
    before :once do
      dashboard_announcement_setup
    end

    it "view announcements only for observed courses and student" do
      go_to_dashboard
      select_observed_student(@student.name)

      expect(announcement_item(@announcement7.id)).to be_displayed
      filter_announcements_list_by("Read")
      expect(announcement_item(@announcement5.id)).to be_displayed
      expect(all_announcement_items.size).to eq(1)

      select_observed_student(@student2.name)
      expect(element_exists?(announcement_item_prefix_selector)).to be_falsey
    end

    it "keeps read state unchanged for observer actions" do
      go_to_dashboard
      select_observed_student(@student.name)

      expect(announcement_item_mark_read(@announcement7.id)).to be_displayed
      announcement_item_mark_read(@announcement7.id).click

      filter_announcements_list_by("Read")
      wait_for_ajaximations
      expect(element_exists?(announcement_item_selector(@announcement7.id))).to be_falsey
    end

    it "navigates to observed courses announcements page" do
      go_to_dashboard
      select_observed_student(@student.name)

      expect(announcement_item_title(@announcement7.id)).to be_displayed
      announcement_item_title(@announcement7.id).click
      expect(driver.current_url).to include("/courses/#{@course1.id}/discussion_topics/#{@announcement7.id}")
    end
  end

  context "People widget as observer" do
    it "view course staff only for observed courses and student" do
      go_to_dashboard
      select_observed_student(@student.name)

      expect(message_instructor_button(@teacher1.id, @course1.id)).to be_displayed
      expect(element_exists?(message_instructor_button_selector(@teacher2.id, @course2.id))).to be_falsey

      select_observed_student(@student2.name)
      expect(message_instructor_button(@teacher2.id, @course2.id)).to be_displayed
      expect(element_exists?(message_instructor_button_selector(@teacher1.id, @course1.id))).to be_falsey
    end

    it "sends message to instructor as observer" do
      go_to_dashboard
      select_observed_student(@student.name)

      expect(message_instructor_button(@teacher1.id, @course1.id)).to be_displayed
      message_instructor_button(@teacher1.id, @course1.id).click
      wait_for_ajaximations
      expect(message_modal_subject_input).to be_displayed
      message_modal_subject_input.send_keys("Observer")
      expect(message_modal_body_textarea).to be_displayed
      message_modal_body_textarea.send_keys("Observer")
      message_modal_send_button.click

      message = ConversationMessage.last
      expect(message.author_id).to eq(@observer.id)
    end
  end
end
