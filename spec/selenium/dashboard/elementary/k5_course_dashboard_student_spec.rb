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
require_relative "../pages/k5_modules_tab_page"
require_relative "../pages/k5_schedule_tab_page"
require_relative "../pages/k5_resource_tab_page"
require_relative "../../../helpers/k5_common"
require_relative "../shared_examples/k5_announcements_shared_examples"
require_relative "../shared_examples/k5_navigation_tabs_shared_examples"

describe "student k5 course dashboard" do
  include_context "in-process server selenium tests"
  include K5DashboardPageObject
  include K5DashboardCommonPageObject
  include K5GradesTabPageObject
  include K5ModulesTabPageObject
  include K5ScheduleTabPageObject
  include K5ResourceTabPageObject
  include K5Common

  before :once do
    student_setup
  end

  before do
    user_session @student
  end

  context "course dashboard standard" do
    it "lands on course dashboard when course card is clicked" do
      get "/"

      click_dashboard_card
      wait_for_ajaximations

      expect(retrieve_title_text).to match(/#{@subject_course_title}/)
      expect(home_tab).to be_displayed
      expect(schedule_tab).to be_displayed
      expect(grades_tab).to be_displayed
    end

    it "saves tab information for refresh" do
      get "/courses/#{@subject_course.id}#home"

      select_schedule_tab
      refresh_page
      wait_for_ajaximations

      expect(driver.current_url).to match(/#schedule/)
    end

    it "has front page displayed if there is one" do
      wiki_page_data = "Here's where we have content"
      @subject_course.wiki_pages.create!(title: "K5 Course Front Page", body: wiki_page_data).set_as_front_page!

      get "/courses/#{@subject_course.id}#home"

      expect(front_page_info.text).to eq(wiki_page_data)
    end

    it "has an empty state graphic when there is no subject home content" do
      get "/courses/#{@subject_course.id}#home"

      expect(empty_subject_home).to be_displayed
    end

    it "displays modules empty state if no published module exists" do
      get "/courses/#{@subject_course.id}#modules"
      expect(modules_tab).to be_displayed
      expect(empty_modules_image).to be_displayed

      create_course_module("unpublished")
      get "/courses/#{@subject_course.id}#modules"
      expect(modules_tab).to be_displayed
      expect(empty_modules_image).to be_displayed
    end

    it "loads the dashboard for public courses even if unauthenticated" do
      @subject_course.is_public = true
      @subject_course.save!
      destroy_session

      get "/courses/#{@subject_course.id}#home"

      expect(retrieve_title_text).to match(/#{@subject_course_title}/)
      expect(home_tab).to be_displayed
      expect(schedule_tab).to be_displayed
      expect(empty_subject_home).to be_displayed
    end

    it_behaves_like "K5 Subject Home Tab"
  end

  context "course modules tab" do
    before :once do
      create_course_module
    end

    it "has module present when provisioned" do
      get "/courses/#{@subject_course.id}#modules"

      expect(module_item(@module_title)).to be_displayed
    end

    it "allows for expand and collapse of module" do
      get "/courses/#{@subject_course.id}#modules"

      expect(module_assignment(@module_assignment_title)).to be_displayed
      expect(expand_collapse_module).to be_displayed

      click_expand_collapse
      expect(module_assignment(@module_assignment_title)).not_to be_displayed
    end

    it "navigates to module tasks when clicked" do
      get "/courses/#{@subject_course.id}#modules"

      click_module_assignment(@module_assignment_title)
      wait_for_ajaximations

      expect(assignment_page_title.text).to eq(@module_assignment_title)
    end
  end

  context "subject schedule tab" do
    it "loads the planner for students who have observer enrollment with no linked students" do
      course_with_teacher(user: @student, active_all: true)
      observer_course = course_factory(active_all: true)
      observer_course.enroll_user(@student, "ObserverEnrollment", enrollment_state: "active")

      get "/courses/#{@subject_course.id}#schedule"
      expect(today_header).to be_displayed
    end
  end

  context "subject resources tab" do
    it "shows the Important Info for subject resources tab" do
      important_info_text = "Show me what you can do"
      create_important_info_content(@subject_course, important_info_text)
      create_lti_resource("fake LTI")
      get "/courses/#{@subject_course.id}#resources"

      expect(important_info_content).to include_text(important_info_text)
    end
  end

  context "subject groups tab existence" do
    it "has no groups tab when there are no groups" do
      get "/courses/#{@subject_course.id}"

      expect(groups_tab_exists?).to be_falsey
    end
  end

  context "subject groups tab functions for student" do
    before :once do
      category = @subject_course.group_categories.create!(name: "category", self_signup: "enabled")
      @group1 = @subject_course.groups.create!(name: "Test Group1", group_category: category)
      @group2 = @subject_course.groups.create!(name: "Test Group2", group_category: category)
    end

    it "has the groups tab available" do
      get "/courses/#{@subject_course.id}"

      expect(groups_tab_exists?).to be_truthy
    end

    it "shows the groups the student can join" do
      get "/courses/#{@subject_course.id}#groups"

      titles_list = group_titles_text_list
      expect(titles_list.count).to eq(2)
      expect(titles_list.first).to match(@group1.name)
      expect(titles_list.first).to match(@group1.group_category.name)
    end

    it "allows student to join group" do
      get "/courses/#{@subject_course.id}#groups"

      buttons_list = group_management_buttons("Join")

      click_group_join_button(buttons_list.first)

      expect(group_management_buttons("Leave").count).to eq(1)
      expect(group_management_buttons("Switch To").count).to eq(1)

      click_group_join_button(group_management_buttons("Switch To").first)
      click_group_join_button(group_management_buttons("Leave").first)

      expect(group_management_buttons("Join").count).to eq(2)
    end
  end

  context "subject tab navigation shared examples" do
    it_behaves_like "k5 subject navigation tabs"
  end
end
