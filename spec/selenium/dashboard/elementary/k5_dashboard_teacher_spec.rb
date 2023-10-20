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
require_relative "../pages/k5_schedule_tab_page"
require_relative "../../../helpers/k5_common"
require_relative "../shared_examples/k5_announcements_shared_examples"

describe "teacher k5 dashboard" do
  include_context "in-process server selenium tests"
  include K5DashboardPageObject
  include K5DashboardCommonPageObject
  include K5GradesTabPageObject
  include K5ResourceTabPageObject
  include K5ScheduleTabPageObject
  include K5Common

  before :once do
    teacher_setup
  end

  before do
    user_session @homeroom_teacher
  end

  context "homeroom dashboard standard" do
    it "shows homeroom enabled for course", :ignore_js_errors do
      get "/courses/#{@homeroom_course.id}/settings"

      expect(is_checked(enable_homeroom_checkbox_selector)).to be_truthy
    end

    it "provides the homeroom dashboard tabs on dashboard" do
      get "/"

      expect(welcome_title).to be_present
      expect(homeroom_tab).to be_displayed
      expect(schedule_tab).to be_displayed
      expect(grades_tab).to be_displayed
      expect(resources_tab).to be_displayed
    end

    it "saves tab information for refresh" do
      get "/"

      select_schedule_tab
      refresh_page
      wait_for_ajaximations

      expect(driver.current_url).to match(/#schedule/)
    end

    it "navigates to homeroom course when homeroom when homeroom title clicked" do
      get "/"

      click_homeroom_course_title(@course_name)
      wait_for_ajaximations

      expect(driver.current_url).to include("/courses/#{@homeroom_course.id}")
    end

    it "does not show homeroom course on dashboard" do
      get "/"

      expect(element_exists?(course_card_selector(@course_name))).to be(false)
      expect(element_exists?(course_card_selector(@subject_course_title))).to be(true)
    end

    it "shows Important Info on the course navigation list" do
      get "/courses/#{@homeroom_course.id}"

      expect(important_info_link).to include_text("Important Info")
    end
  end

  context "homeroom announcements" do
    it "navigates to homeroom course announcement edit when announcement button is clicked" do
      get "/"

      expect(announcement_button).to be_displayed
      click_announcement_button
      wait_for_ajaximations

      expect(driver.current_url).to include(
        "/courses/#{@homeroom_course.id}/discussion_topics/new?is_announcement=true"
      )
    end

    it "goes to the homeroom announcement for edit when clicked" do
      announcement_title = "K5 Let's do this"
      announcement =
        new_announcement(@homeroom_course, announcement_title, "So happy to see all of you.")

      get "/"

      click_announcement_edit_pencil
      wait_for_ajaximations

      expect(driver.current_url).to include(
        "/courses/#{@homeroom_course.id}/discussion_topics/#{announcement.id}/edit"
      )
    end

    it "provides the +Announcement button along with no recent announcements" do
      announcement_heading1 = "K5 Do this"
      announcement_content1 = "So happy to see all of you."
      announcement1 =
        new_announcement(@homeroom_course, announcement_heading1, announcement_content1)
      announcement1.update!(posted_at: 15.days.ago)

      get "/"

      expect(no_recent_announcements).to be_displayed
      expect(announcement_button).to be_displayed
    end

    it "opens up the announcement when announcement title is clicked" do
      announcement = new_announcement(@homeroom_course, "Cool title", "Content...")
      get "/"

      click_announcement_title("Cool title")
      wait_for_ajaximations

      expect(driver.current_url).to include(
        "/courses/#{@homeroom_course.id}/discussion_topics/#{announcement.id}"
      )
    end

    it_behaves_like "k5 homeroom announcements"

    it_behaves_like "k5 homeroom announcements with multiple homerooms", :teacher
  end

  context "course cards" do
    it "shows latest announcement on subject course card" do
      new_announcement(@subject_course, "K5 Let's do this", "So happy to see all of you.")
      announcement2 = new_announcement(@subject_course, "K5 Latest", "Let's get to work!")

      get "/"

      expect(course_card_announcement(announcement2.title)).to be_displayed
    end

    it "shows course color selection on dashboard card" do
      new_color = "#07AB99"
      @subject_course.update!(course_color: new_color)

      get "/"

      expect(hex_value_for_color(dashboard_card, "background-color")).to eq(new_color)
    end
  end

  context "homeroom dashboard grades panel" do
    it "shows the subjects the teacher is enrolled in" do
      subject_title2 = "Social Studies"
      course_with_teacher(active_all: true, user: @homeroom_teacher, course_name: subject_title2)

      get "/#grades"

      expect(subject_grades_title(@subject_course_title)).to be_displayed
      expect(subject_grades_title(subject_title2)).to be_displayed
    end

    it "provides a button to the gradebook for subject teacher is enrolled in" do
      get "/#grades"

      expect(view_grades_button(@subject_course.id)).to be_displayed
    end

    it "shows the subjects the TA is enrolled in" do
      course_with_ta(active_all: true, course: @subject_course)

      get "/#grades"

      expect(subject_grades_title(@subject_course_title)).to be_displayed
      expect(view_grades_button(@subject_course.id)).to be_displayed
    end

    it "show teacher also as student on grades page" do
      subject_title2 = "Teacher Training"
      course_with_student(active_all: true, user: @homeroom_teacher, course_name: subject_title2)

      get "/#grades"

      expect(subject_grades_title(@subject_course_title)).to be_displayed
      expect(subject_grades_title(subject_title2)).to be_displayed
      expect(subject_grade("--")).to be_displayed
    end
  end

  context "homeroom dashboard resource panel" do
    it "shows the resource panel staff contacts" do
      course_with_ta(course: @homeroom_course, active_enrollment: 1)

      get "/"

      select_resources_tab

      expect(staff_heading(@homeroom_teacher.name)).to be_displayed
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

    it "shows the Important Info for the main resources tab" do
      important_info_text = "Show me what you can do"
      create_important_info_content(@homeroom_course, important_info_text)

      get "/#resources"
      expect(important_info_content).to include_text(important_info_text)
    end

    it "edits important info from via pencil on resource tab" do
      important_info_text = "Show me what you can do"
      create_important_info_content(@homeroom_course, important_info_text)

      get "/#resources"
      expect(important_info_edit_pencil).to be_displayed

      click_important_info_edit_pencil
      expect(driver.current_url).to include("/courses/#{@homeroom_course.id}/assignments/syllabus")
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
      course_with_teacher(
        active_course: 1,
        active_enrollment: 1,
        course_name: second_course_title,
        user: @homeroom_teacher
      )
      get "/#resources"

      click_k5_button(0)

      expect(course_selection_modal).to be_displayed
      expect(course_list.count).to eq(2)
    end

    it "shows the LTI resource scoped to the course", :ignore_js_errors do
      create_lti_resource("New Commons")

      get "/#resources"

      expect(k5_resource_button_names_list).to include "New Commons"
    end
  end

  context "teacher schedule" do
    it "shows a sample preview for teacher view of the schedule tab" do
      get "/#schedule"

      expect(teacher_preview).to be_displayed
    end

    it "shows a sample preview for teacher view of the course schedule tab" do
      get "/courses/#{@subject_course.id}#schedule"

      expect(teacher_preview).to be_displayed
    end
  end

  context "k5 teacher new course creation" do
    before :once do
      @account.root_account.update!(settings: { teachers_can_create_courses: true })
    end

    it "provides a new course button for teacher" do
      get "/"
      expect(new_course_button).to be_displayed
    end

    it "provides a new course modal when new course button clicked" do
      get "/"
      click_new_course_button

      expect(new_course_modal).to be_displayed
    end

    it "closes the course modal when x is clicked" do
      get "/"

      click_new_course_button

      expect(new_course_modal_close_button).to be_displayed

      click_new_course_close_button

      expect(new_course_modal_exists?).to be_falsey
    end

    it "closes the course modal when cancel is clicked" do
      get "/"

      click_new_course_button

      expect(new_course_modal_close_button).to be_displayed

      course_name = "Awesome Course"
      enter_course_name(course_name)
      click_new_course_cancel

      expect(new_course_modal_exists?).to be_falsey
      latest_course = Course.last
      expect(latest_course.name).not_to eq(course_name)
    end

    it "creates course with account name and course name",
       :ignore_js_errors,
       custom_timeout: 30 do
      @sub_account = @account.sub_accounts.create!(name: "test")
      course_with_teacher(
        account: @sub_account,
        active_course: 1,
        active_enrollment: 1,
        course_name: "Amazing course",
        user: @homeroom_teacher
      )

      get "/"
      click_new_course_button

      course_name = "Amazing course 1"
      fill_out_course_modal(@sub_account, course_name)
      click_new_course_create
      wait_for_ajaximations
      latest_course = Course.last
      expect(latest_course.name).to eq(course_name)
      expect(driver.current_url).to include("/courses/#{latest_course.id}/settings")
    end

    it "allows for sync of course to selected homeroom",
       :ignore_js_errors,
       custom_timeout: 30 do
      second_homeroom_course_name = "Second homeroom course"

      course_with_teacher(
        account: @account,
        active_course: 1,
        active_enrollment: 1,
        course_name: second_homeroom_course_name,
        user: @homeroom_teacher
      )
      Course.last.update!(homeroom_course: true)

      get "/"
      click_new_course_button
      new_course_name = "Amazing Course One"
      enter_course_name(new_course_name)
      click_sync_enrollments_checkbox
      click_option(homeroom_select_selector, second_homeroom_course_name)
      click_new_course_create

      expect(new_course_modal_exists?).to be_falsey
      expect(course_homeroom_option(second_homeroom_course_name)).to have_attribute(
        "selected",
        "true"
      )
    end
  end
end
