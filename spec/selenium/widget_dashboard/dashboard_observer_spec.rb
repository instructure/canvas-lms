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
    it "filter observed course items by not submitted" do
      go_to_dashboard
      select_observed_student(@student.name)

      expect(all_course_work_items.size).to eq(3)
      expect(course_work_summary_stats("Due").text).to eq("3\nDue")
      expect(course_work_item(@due_assignment.id)).to be_displayed
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

  context "Recent grades widget as observer" do
    before :once do
      dashboard_recent_grades_setup
      add_widget_to_dashboard(@observer, :recent_grades, 1)
    end

    it "view grades only for observed student" do
      go_to_dashboard
      select_observed_student(@student.name)
      expect(recent_grades_widget.text).to include(@submitted_assignment.name)
      expect(recent_grades_widget.text).to include(@graded_discussion.title)
      expect(recent_grades_widget.text).to include(@graded_quiz.title)
      expect(all_recent_grade_course_name.size).to eq(3)

      select_observed_student(@student2.name)
      expect(recent_grades_widget.text).to include(@graded_assignment.name)
      expect(recent_grades_widget.text).to include(@submitted_discussion.title)
      expect(all_recent_grade_course_name.size).to eq(2)
    end

    it "navigates to grades page when clicking view all grades link" do
      go_to_dashboard

      select_observed_student(@student.name)
      expect(recent_grades_view_all_link).to be_displayed
      recent_grades_view_all_link.click
      expect(driver.current_url).to include("/grades")
    end

    it "navigates to assignment page when clicking open assignment link" do
      submission = @graded_assignment.submission_for_student(@student2)

      go_to_dashboard
      select_observed_student(@student2.name)
      expand_feedback_on_recent_grade(submission.id)

      expect(recent_grade_open_assignment_link(submission.id)).to be_displayed
      recent_grade_open_assignment_link(submission.id).click
      expect(driver.current_url).to include("/courses/#{@course2.id}/assignments/#{@graded_assignment.id}")
    end

    it "navigates to course grades page when clicking what-if grading tool link" do
      submission = @graded_assignment.submission_for_student(@student2)

      go_to_dashboard
      select_observed_student(@student2.name)
      expand_feedback_on_recent_grade(submission.id)

      expect(recent_grade_whatif_link(submission.id)).to be_displayed
      recent_grade_whatif_link(submission.id).click
      expect(driver.current_url).to include("/courses/#{@course2.id}/grades")
    end

    it "navigates to assignment with feedback when clicking view inline feedback link" do
      submission = @graded_discussion.submission_for_student(@student)
      discussion_topic = DiscussionTopic.find_by(assignment_id: @graded_discussion.id)

      go_to_dashboard
      select_observed_student(@student.name)
      expand_feedback_on_recent_grade(submission.id)

      expect(recent_grade_view_feedback_link(submission.id)).to be_displayed
      expect(recent_grade_feedback_section(submission.id).text).to include("Well done!")
      recent_grade_view_feedback_link(submission.id).click
      expect(driver.current_url).to include("/courses/#{@course1.id}/discussion_topics/#{discussion_topic.id}")
    end
  end
end
