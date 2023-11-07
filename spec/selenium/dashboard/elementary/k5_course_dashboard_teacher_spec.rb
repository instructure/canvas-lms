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
require_relative "../pages/k5_resource_tab_page"
require_relative "../../../helpers/k5_common"
require_relative "../../courses/pages/course_settings_page"
require_relative "../shared_examples/k5_announcements_shared_examples"
require_relative "../shared_examples/k5_navigation_tabs_shared_examples"

describe "teacher k5 course dashboard" do
  include_context "in-process server selenium tests"
  include K5DashboardPageObject
  include K5DashboardCommonPageObject
  include K5GradesTabPageObject
  include K5ModulesTabPageObject
  include K5ResourceTabPageObject
  include K5Common
  include CourseSettingsPage

  before :once do
    teacher_setup
  end

  before do
    user_session @homeroom_teacher
  end

  context "course dashboard standard" do
    it "lands on course dashboard when course card is clicked" do
      get "/"

      click_dashboard_card
      wait_for_ajaximations

      expect(retrieve_title_text).to match(/#{@subject_course_title}/)
      expect(home_tab).to be_displayed
      expect(schedule_tab).to be_displayed
      expect(modules_tab).to be_displayed
      expect(grades_tab).to be_displayed
    end

    it "saves tab information for refresh" do
      get "/courses/#{@subject_course.id}#home"

      select_schedule_tab
      refresh_page
      wait_for_ajaximations

      expect(driver.current_url).to match(/#schedule/)
    end
  end

  context "home tab" do
    it "has front page displayed if there is one" do
      wiki_page_data = "Here's where we have content"
      @course.wiki_pages.create!(title: "K5 Course Front Page", body: wiki_page_data).set_as_front_page!

      get "/courses/#{@subject_course.id}#home"

      expect(front_page_info.text).to eq(wiki_page_data)
    end

    it "has manage subject button" do
      get "/courses/#{@subject_course.id}#home"

      expect(manage_button).to be_displayed
    end

    it "has an empty state graphic when there is no subject home content" do
      get "/courses/#{@subject_course.id}#home"

      expect(empty_subject_home).to be_displayed
      expect(manage_home_button).to be_displayed
    end

    it "opens the course setting path when manage subject button is clicked" do
      get "/courses/#{@subject_course.id}#home"

      click_manage_button

      expect(driver.current_url).to match(course_settings_path(@subject_course.id))
    end

    it "shows Important Info in the course navigation list" do
      get "/courses/#{@subject_course.id}/settings"

      expect(important_info_link).to include_text("Important Info")
    end

    it "goes to acting student course home when student view button is clicked" do
      get "/courses/#{@subject_course.id}#modules"

      expect(student_view_button).to be_displayed

      click_student_view_button

      expect(leave_student_view).to include_text("Leave Student View")
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

    it "navigates to module task in edit mode when clicked" do
      get "/courses/#{@subject_course.id}#modules"

      click_module_assignment(@module_assignment_title)
      wait_for_ajaximations

      expect(assignment_page_title.text).to eq(@module_assignment_title)
      expect(assignment_edit_button).to be_displayed
    end

    it "shows add module modal when +Module button is clicked" do
      Account.site_admin.disable_feature! :differentiated_modules
      get "/courses/#{@subject_course.id}#modules"

      click_add_module_button

      expect(add_module_modal).to be_displayed
    end

    it "shows add module items modal when + button is clicked" do
      get "/courses/#{@subject_course.id}#modules"

      click_add_module_item_button

      expect(add_module_item_modal).to be_displayed
    end

    it "provides drag handles for item moves" do
      get "/courses/#{@subject_course.id}#modules"

      expect(drag_handle).to be_displayed
    end
  end

  context "course color selection" do
    it "allows for available color to be selected", :ignore_js_errors, custom_timeout: 30 do
      get "/courses/#{@subject_course.id}/settings"
      visit_course_details_tab

      click_pink_color_button

      wait_for_new_page_load(submit_form("#course_form"))
      pink_color = "#DF6B91"

      expect(element_value_for_attr(selected_color_input, "value")).to eq(pink_color)
      expect(hex_value_for_color(course_color_preview, "background-color")).to eq(pink_color)
    end

    it "allows for hex color to be input", :ignore_js_errors do
      get "/courses/#{@subject_course.id}/settings"
      visit_course_details_tab

      new_color = "#07AB99"
      input_color_hex_value(new_color)
      wait_for_new_page_load(submit_form("#course_form"))

      expect(hex_value_for_color(course_color_preview, "background-color")).to eq(new_color)
    end

    it "shows the course color selection on the course header" do
      new_color = "#07AB99"
      @subject_course.update!(course_color: new_color)

      get "/courses/#{@subject_course.id}#home"

      expect(hex_value_for_color(dashboard_header, "background-color")).to eq(new_color)
    end
  end

  context "course tab navigation" do
    let(:lti_a) { "LTI Resource A" }
    let(:lti_b) { "LTI Resource B" }
    let(:navigation_names) { ["Home", "Schedule", "Modules", "Grades", "Groups", lti_a, lti_b] }

    before :once do
      @resource_a = "context_external_tool_#{create_lti_resource(lti_a).id}"
      @resource_b = "context_external_tool_#{create_lti_resource(lti_b).id}"
    end

    it "shows the k5 navigation tabs and LTIs on the settings page" do
      get "/courses/#{@subject_course.id}/settings#tab-navigation"

      navigation_list = navigation_items

      expect(navigation_list.count).to eq(7)

      navigation_names.count.times do |x|
        expect(navigation_list[x]).to include_text(navigation_names[x])
      end
    end
  end

  context "course tab navigation shared examples" do
    it_behaves_like "k5 subject navigation tabs"
  end

  context "course grades tab" do
    it "shows image and view grades button for teacher" do
      get "/courses/#{@subject_course.id}#grades"

      expect(empty_grades_image).to be_displayed
      expect(view_grades_button(@subject_course.id)).to be_displayed
    end

    it "shows fake student grades in student view" do
      create_assignment(@subject_course, "a cool assignment", "woohoo", 100)
      get "/courses/#{@subject_course.id}#grades"

      click_student_view_button
      expect(grades_assignments_list[0].text).to include("a cool assignment")
      expect(grades_total.text).to include("Total: n/a")
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

  context "subject groups tab" do
    it "shows the image and manage groups button for teacher" do
      get "/courses/#{@subject_course.id}#groups"

      expect(empty_groups_image).to be_displayed
      expect(manage_groups_button).to be_displayed
    end

    it "goes to the groups page when manage groups button is clicked" do
      get "/courses/#{@subject_course.id}#groups"

      click_manage_groups_button
      expect(driver.current_url).to include("/courses/#{@subject_course.id}/groups")
    end
  end
end
