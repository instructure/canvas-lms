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
require_relative "../pages/k5_dashboard_page"
require_relative "../pages/k5_dashboard_common_page"
require_relative "../pages/k5_grades_tab_page"
require_relative "../pages/k5_resource_tab_page"
require_relative "../../../helpers/k5_common"
require_relative "../../grades/setup/gradebook_setup"
require_relative "../pages/k5_important_dates_section_page"
require_relative "../shared_examples/k5_important_dates_shared_examples"
require_relative "../shared_examples/k5_announcements_shared_examples"

describe "student k5 dashboard" do
  include_context "in-process server selenium tests"
  include K5DashboardPageObject
  include K5DashboardCommonPageObject
  include K5GradesTabPageObject
  include K5ResourceTabPageObject
  include K5Common
  include GradebookSetup
  include K5ImportantDatesSectionPageObject

  before :once do
    student_setup
  end

  before do
    user_session @student
  end

  context "homeroom dashboard standard" do
    it "provides the homeroom dashboard tabs on dashboard" do
      get "/"

      expect(welcome_title).to be_present
      expect(homeroom_tab).to be_displayed
      expect(schedule_tab).to be_displayed
      expect(grades_tab).to be_displayed
      expect(resources_tab).to be_displayed
    end

    it "dashboard tabs are sticky when scrolling down on homeroom view" do
      create_courses(10, enroll_user: @student, return_type: :record)

      get "/"
      wait_for_ajaximations

      driver.execute_script("window.scrollTo(0, document.body.scrollHeight)")
      wait_for_ajaximations

      expect(welcome_title).to be_present
      expect(homeroom_tab).to be_displayed
    end
  end

  context "homeroom section" do
    it "shows no announcement creation button when there are no announcements" do
      get "/"

      expect(announcement_button_exists?).to be_falsey
    end

    it_behaves_like "k5 homeroom announcements"

    it_behaves_like "k5 homeroom announcements with multiple homerooms", :student
  end

  context "dashboard cards" do
    it "shows 1 assignment due today" do
      create_dated_assignment(@subject_course, "assignment three", Time.zone.today, 10)

      get "/"

      expect(subject_items_due(@subject_course_title)).to include_text("1 due today")
    end

    it "navigates to the planner for subject when due today is clicked", custom_timeout: 30 do
      create_dated_assignment(@subject_course, "assignment three", Time.zone.today, 10)

      get "/"

      expect(element_value_for_attr(subject_items_due(@subject_course_title), "href")).to include("/courses/#{@subject_course.id}?focusTarget=today#schedule")

      click_duetoday_subject_item(@subject_course_title)
      expect(driver.current_url).to include("/courses/#{@subject_course.id}#schedule")
    end

    it "shows 1 assignment missing today" do
      create_dated_assignment(@subject_course, "assignment three", 3.days.ago, 10)

      get "/"

      expect(subject_items_missing(@subject_course_title)).to include_text("1 missing")
    end

    it "navigates to the planner for subject when assignment missing clicked" do
      create_dated_assignment(@subject_course, "assignment three", 3.days.ago, 10)

      get "/"

      expect(subject_items_missing(@subject_course_title).attribute("href")).to include("/courses/#{@subject_course.id}?focusTarget=missing-items#schedule")

      click_missing_subject_item(@subject_course_title)
      expect(driver.current_url).to include("/courses/#{@subject_course.id}#schedule")
    end

    it "shows subject course on dashboard" do
      get "/"

      expect(element_exists?(course_card_selector(@course_name))).to be(false)
      expect(element_exists?(course_card_selector(@subject_course_title))).to be(true)
    end

    it "shows latest announcement on subject course card" do
      new_announcement(@subject_course, "K5 Let's do this", "So happy to see all of you.")
      announcement2 = new_announcement(@subject_course, "K5 Latest", "Let's get to work!")

      get "/"

      expect(course_card_announcement(announcement2.title)).to be_displayed
    end

    it "navigates to subject when subject card title is clicked" do
      get "/"

      subject_href = element_value_for_attr(subject_title_link(@subject_course_title), "href")
      navigate_to_subject(@subject_course_title)
      wait_for_ajaximations

      expect(driver.current_url).to eq(subject_href)
    end

    it "shows no assignments due today" do
      create_dated_assignment(@subject_course, "assignment three", 1.week.from_now(Time.zone.now), 10)

      get "/"

      expect(nothing_due(@subject_course_title)).to be_displayed
    end
  end

  context "schedule tab" do
    it "dashboard tabs are sticky when scrolling down on planner view" do
      5.times do
        create_dated_assignment(@subject_course, "old assignment", 1.week.from_now(Time.zone.now), 10)
      end

      get "/"
      select_schedule_tab
      wait_for_ajaximations

      driver.execute_script("window.scrollTo(0, document.body.scrollHeight)")
      wait_for_ajaximations

      expect(welcome_title).to be_present
      expect(homeroom_tab).to be_displayed
    end
  end

  context "homeroom dashboard student grades panel" do
    let(:math_subject_grade) { "75" }

    let(:assignment) { create_and_submit_assignment(@subject_course, "Assignment 1", "new assignment", 100) }

    it "shows the grades panel with two courses" do
      subject_title2 = "Social Studies"
      course_with_student(active_all: true, user: @student, course_name: subject_title2)

      get "/#grades"

      expect(subject_grades_title(@subject_course_title)).to be_displayed
      expect(subject_grades_title(subject_title2)).to be_displayed
    end

    it "shows the grades in default percentage format" do
      assignment.grade_student(@student, grader: @homeroom_teacher, score: math_subject_grade, points_deducted: 0)

      get "/#grades"

      expect(subject_grade(math_subject_grade + "%")).to be_displayed
    end

    it "shows the grades with a different grading scheme" do
      grading_standard = create_grading_standard(@subject_course)
      @subject_course.update!(grading_standard_enabled: true, grading_standard_id: grading_standard.id)

      assignment.grade_student(@student, grader: @homeroom_teacher, score: math_subject_grade, points_deducted: 0)

      scheme_subject_grade = "You got this"
      get "/#grades"

      expect(subject_grade(scheme_subject_grade)).to be_displayed
    end

    it "shows the grades for a different grading period" do
      @course = @subject_course
      create_grading_periods("Fall Term")
      associate_course_to_term("Fall Term")
      assignment.update!(due_at: 1.week.ago)
      assignment.grade_student(@student, grader: @homeroom_teacher, score: "90", points_deducted: 0)

      get "/#grades"

      click_option(grading_period_dropdown_selector, "GP Ended")

      expect(subject_grade("90%")).to be_displayed
    end

    it "shows two dashes and empty progress bar if no grades are available for a course" do
      skip "FOO-3525 (10/6/2023)"
      get "/#grades"

      expect(subject_grade("--")).to be_displayed
      expect(grade_progress_bar("0")).to be_displayed
    end

    it "show the progress bar with the appropriate progress" do
      skip "FOO-3525 (10/6/2023)"
      assignment.grade_student(@student, grader: @homeroom_teacher, score: math_subject_grade, points_deducted: 0)

      get "/#grades"

      expect(grade_progress_bar(math_subject_grade)).to be_displayed
    end
  end

  context "homeroom dashboard resource panel" do
    it "shows the resource panel staff contacts" do
      course_with_ta(
        course: @homeroom_course,
        active_enrollment: 1
      )

      @ta.email = "ta_person@example.com"
      @ta.save!

      get "/"

      select_resources_tab

      expect(staff_heading(@teacher_name)).to be_displayed
      expect(instructor_role("Teacher")).to be_displayed

      expect(staff_heading(@ta.name)).to be_displayed
      expect(instructor_role("Teaching Assistant")).to be_displayed
    end

    it "shows the bio for a contact if the profiles are enabled" do
      @homeroom_course.account.settings[:enable_profiles] = true
      @homeroom_course.account.save!

      user_profile = @homeroom_teacher.profile

      bio = "teacher profile bio"
      title = "teacher profile title"

      user_profile.bio = bio
      user_profile.title = title
      user_profile.save!

      get "/#resources"

      expect(instructor_bio(bio)).to be_displayed
    end

    it "allows student to send message to teacher", custom_timeout: 30 do
      get "/#resources"

      click_message_button

      expect(message_modal_displayed?(@homeroom_teacher.name)).to be_truthy

      expect(is_send_available?).to be_falsey

      replace_content(subject_input, "need help")
      replace_content(message_input, "hey teach, I really need help with these fractions.")

      expect(is_send_available?).to be_truthy

      click_send_button

      wait_for_ajaximations

      expect(is_modal_gone?(@homeroom_teacher.name)).to be_truthy
      expect(Conversation.count).to eq(1)
    end

    it "allows student to cancel message to teacher" do
      get "/#resources"

      click_message_button

      expect(is_cancel_available?).to be_truthy

      replace_content(subject_input, "need help")
      replace_content(message_input, "hey teach, I really need help with these fractions.")

      click_cancel_button

      wait_for_ajaximations

      expect(is_modal_gone?(@homeroom_teacher.name)).to be_truthy
      expect(Conversation.count).to eq(0)
    end

    it "shows the Important Info for the main resources tab" do
      important_info_text = "Show me what you can do"
      create_important_info_content(@homeroom_course, important_info_text)

      get "/#resources"
      expect(important_info_content).to include_text(important_info_text)
    end

    it "shows the Important Info multiple homerooms for the main resources tab" do
      important_info_text1 = "Show me what you can do"
      important_info_text2 = "More homeroom info"
      create_important_info_content(@homeroom_course, important_info_text1)

      course_with_student(active_all: true, user: @student, course_name: "Second Homeroom")
      second_homeroom_course = Course.last
      second_homeroom_course.update!(homeroom_course: true)
      create_important_info_content(second_homeroom_course, important_info_text2)

      get "/#resources"

      expect(important_info_text_list[0]).to eq(important_info_text1)
      expect(important_info_text_list[1]).to eq(important_info_text2)
    end
  end

  context "homeroom dashboard resource panel LTI resources" do
    let(:lti_resource_name) { "Commons" }

    before :once do
      create_lti_resource(lti_resource_name)
    end

    it "shows the LTI resources for account and course on resources page" do
      get "/#resources"

      expect(k5_app_buttons[0].text).to eq lti_resource_name
    end

    it "shows course modal to choose which LTI resource context when button clicked", :ignore_js_errors do
      second_course_title = "Second Course"
      course_with_student(
        active_course: 1,
        active_enrollment: 1,
        course_name: second_course_title,
        user: @student
      )
      get "/#resources"

      click_k5_button(0)

      expect(course_selection_modal).to be_displayed
      expect(course_list.count).to eq(2)
    end
  end
end
