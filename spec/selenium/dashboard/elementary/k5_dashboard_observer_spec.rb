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
require_relative "../pages/dashboard_page"
require_relative "../pages/k5_dashboard_page"
require_relative "../pages/k5_dashboard_common_page"
require_relative "../pages/k5_grades_tab_page"
require_relative "../../grades/setup/gradebook_setup"
require_relative "../pages/k5_schedule_tab_page"
require_relative "../pages/k5_resource_tab_page"
require_relative "../../../helpers/k5_common"
require_relative "../shared_examples/k5_navigation_tabs_shared_examples"
require_relative "../shared_examples/k5_subject_grades_shared_examples"
require_relative "../shared_examples/k5_schedule_shared_examples"

describe "observer k5 dashboard" do
  include_context "in-process server selenium tests"
  include DashboardPage
  include K5DashboardPageObject
  include K5DashboardCommonPageObject
  include K5Common
  include K5ScheduleTabPageObject
  include K5GradesTabPageObject
  include GradebookSetup
  include K5ResourceTabPageObject
  include ObserverEnrollmentsHelper

  before :once do
    student_setup
    observer_setup
  end

  before do
    user_session @observer
    driver.manage.delete_cookie("#{ObserverEnrollmentsHelper::OBSERVER_COOKIE_PREFIX}#{@observer.id}")
  end

  context "single observed student" do
    it "defaults to the one observed student" do
      get "/"

      expect(element_value_for_attr(observed_student_dropdown, "value")).to eq("K5Student")
    end

    it "shows the homeroom announcement and subject for the one observed student" do
      announcement_heading1 = "K5 Do this"
      announcement_content1 = "So happy to see all of you."
      new_announcement(@homeroom_course, announcement_heading1, announcement_content1)

      get "/"

      expect(dashboard_card_specific_subject("Math")).to be_displayed
      expect(announcement_title(announcement_heading1)).to be_displayed
    end

    it "show the grades progress bar with the appropriate progress" do
      skip "FOO-3808 (10/6/2023)"
      subject_grade = "75"

      assignment = create_and_submit_assignment(@subject_course, "Assignment 1", "new assignment", 100)
      assignment.grade_student(@student, grader: @homeroom_teacher, score: subject_grade, points_deducted: 0)

      get "/#grades"

      expect(grade_progress_bar(subject_grade)).to be_displayed
    end

    it "shows the Important Info for the main resources tab" do
      important_info_text = "Show me what you can do"
      create_important_info_content(@homeroom_course, important_info_text)

      get "/#resources"
      expect(important_info_content).to include_text(important_info_text)
    end

    it "shows the LTI resources for account and course on resources page" do
      lti_resource_name = "Commons"
      create_lti_resource(lti_resource_name)

      get "/#resources"

      expect(k5_app_buttons[0].text).to eq lti_resource_name
    end
  end

  context "multiple observed students" do
    before :once do
      @new_students = []
      2.times do |x|
        course_with_student(
          active_all: true,
          name: "My#{x + 1} Student",
          course: @homeroom_course
        )
        add_linked_observer(@student, @observer, root_account: @account)
        @new_students << @student
      end

      course_with_student(
        active_course: true,
        course_name: "Art",
        user: @new_students[0]
      )
      @art_course = @course

      course_with_student(
        active_all: true,
        user: @new_students[1],
        course: @subject_course
      )
    end

    it "provides a dropdown for multiple observed students" do
      get "/"

      expect(observed_student_dropdown).to be_displayed

      expect(element_value_for_attr(observed_student_dropdown, "value")).to eq("K5Student")
    end

    it "selects a student from the dropdown list" do
      get "/"

      click_observed_student_option("My1 Student")

      expect(element_value_for_attr(observed_student_dropdown, "value")).to eq("My1 Student")
      expect(dashboard_card_specific_subject("Art")).to be_displayed
    end

    it "selects allows for searching for a student in dropdown list" do
      get "/"

      observed_student_dropdown.send_keys([:control, "a"], :backspace, "My2")
      click_observed_student_option("My2 Student")

      expect(element_value_for_attr(observed_student_dropdown, "value")).to eq("My2 Student")
      expect(dashboard_card_specific_subject("Math")).to be_displayed
    end

    it "shows the observers name first if observer is also a student" do
      course_with_student(
        active_all: true,
        user: @observer,
        course: @art_course
      )
      get "/"

      expect(element_value_for_attr(observed_student_dropdown, "value")).to eq("Mom")
      expect(dashboard_card_specific_subject("Art")).to be_displayed
    end

    it "shows the dropdown picker on subject dashboard and first student on list" do
      get "/courses/#{@subject_course.id}#home"

      expect(element_value_for_attr(observed_student_dropdown, "value")).to eq("K5Student")
    end

    it "selects student from list on subject drop down menu", :ignore_js_errors do
      get "/courses/#{@subject_course.id}#home"

      click_observed_student_option("My2 Student")

      expect(element_value_for_attr(observed_student_dropdown, "value")).to eq("My2 Student")
    end

    it "allows for searching for a student in subject dropdown list", :ignore_js_errors do
      get "/courses/#{@subject_course.id}#home"

      observed_student_dropdown.send_keys([:control, "a"], :backspace, "My2")
      click_observed_student_option("My2 Student")

      expect(element_value_for_attr(observed_student_dropdown, "value")).to eq("My2 Student")
    end

    it "switches to the classic dashboard when selecting a non-k5 student" do
      @course2 = course_factory(active_all: true)
      @student2 = user_factory(active_all: true, name: "Classic Student")
      @course2.enroll_student(@student2)
      @course2.enroll_user(@observer, "ObserverEnrollment", associated_user_id: @student2, enrollment_state: :active)

      get "/"
      expect(homeroom_tab).to be_displayed # k5 dashboard only
      toggle_k5_setting(@account, false)
      click_observed_student_option("Classic Student")
      expect(todo_list_header).to be_displayed # classic dashboard only
    end
  end

  context "k5 subject dashboard observee selections" do
    let(:wiki_page_data) { "Here's where we have content" }

    before :once do
      @subject_course.wiki_pages.create!(title: "K5 Course Front Page", body: wiki_page_data).set_as_front_page!
    end

    it "has students front page displayed if there is one" do
      get "/courses/#{@subject_course.id}#home"

      expect(front_page_info.text).to eq(wiki_page_data)
    end

    it "shows schedule info for course items" do
      skip("LS-2481 Planner work todo")
      create_dated_assignment(@subject_course, "today assignment1", @now)

      get "/courses/#{@subject_course.id}#schedule"

      expect(today_header).to be_displayed
      expect(schedule_item.text).to include("today assignment1")
    end

    it "shows the Important Info for subject resources tab" do
      important_info_text = "Show me what you can do"
      create_important_info_content(@subject_course, important_info_text)
      create_lti_resource("fake LTI")
      get "/courses/#{@subject_course.id}#resources"

      expect(important_info_content).to include_text(important_info_text)
    end

    it "shows the observers name first if observer is also a student" do
      skip("LS-3152: failing about half the time - showing the student not the observer")
      course_with_student(
        active_all: true,
        user: @observer,
        course: @subject_course
      )

      get "/courses/#{@subject_course.id}#home"

      expect(element_value_for_attr(observed_student_dropdown, "value")).to eq("Mom")
      expect(front_page_info.text).to eq(wiki_page_data)
    end
  end

  context "observee pairing modal" do
    it "brings up modal when button selected" do
      get "/"

      click_observed_student_option("Add Student")

      expect(pairing_modal).to be_displayed
    end

    it "closes when Close button is selected" do
      get "/"

      click_observed_student_option("Add Student")
      click_close_pairing_button

      expect(wait_for_no_such_element { pairing_modal }).to be_truthy
    end

    it "pairs observer and observee when pairing code added" do
      course_with_student(
        active_all: true,
        name: "Transfer Student",
        course: @homeroom_course
      )
      pairing_code = @student.generate_observer_pairing_code

      get "/"

      click_observed_student_option("Add Student")
      pairing_code_input.send_keys(pairing_code.code)
      click_pairing_button

      expect(wait_for_no_such_element { pairing_modal }).to be_truthy
    end

    it "retains modal when invalid pairing code added" do
      get "/"

      click_observed_student_option("Add Student")
      pairing_code_input.send_keys("xxxXXX")
      click_pairing_button
      expect_instui_flash_message("Failed pairing student.")
      expect(pairing_modal).to be_displayed
    end
  end

  context "course tab navigation shared examples" do
    it_behaves_like "k5 subject navigation tabs"
  end

  context "subject grades shared examples" do
    it_behaves_like "k5 subject grades"
  end

  context "schedule shared examples" do
    it_behaves_like "k5 schedule"
  end
end
