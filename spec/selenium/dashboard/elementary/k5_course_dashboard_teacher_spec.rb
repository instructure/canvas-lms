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

require_relative '../../common'
require_relative '../pages/k5_dashboard_page'
require_relative '../../helpers/k5_common'
require_relative '../../courses/pages/course_settings_page'

describe "teacher k5 course dashboard" do
  include_context "in-process server selenium tests"
  include K5PageObject
  include K5Common
  include CourseSettingsPage

  before :once do
    teacher_setup
  end

  before :each do
    user_session @homeroom_teacher
  end

  context 'course dashboard standard' do
    it 'lands on course dashboard when course card is clicked' do
      get "/"

      click_dashboard_card
      wait_for_ajaximations

      expect(retrieve_title_text).to match(/#{@subject_course_title}/)
      expect(home_tab).to be_displayed
      expect(schedule_tab).to be_displayed
      expect(modules_tab).to be_displayed
      expect(grades_tab).to be_displayed
    end

    it 'saves tab information for refresh' do
      get "/courses/#{@subject_course.id}#home"


      select_schedule_tab
      refresh_page
      wait_for_ajaximations

      expect(driver.current_url).to match(/#schedule/)
    end
  end

  context 'home tab' do
    it 'has front page displayed if there is one' do
      wiki_page_data = "Here's where we have content"
      @course.wiki_pages.create!(:title => "K5 Course Front Page", :body => wiki_page_data).set_as_front_page!

      get "/courses/#{@subject_course.id}#home"

      expect(front_page_info.text).to eq(wiki_page_data)
    end

    it 'has manage subject button' do
      get "/courses/#{@subject_course.id}#home"

      expect(manage_button).to be_displayed
    end

    it 'opens the course setting path when manage subject button is clicked' do
      get "/courses/#{@subject_course.id}#home"

      click_manage_button

      expect(driver.current_url).to match(course_settings_path(@subject_course.id))
    end
  end

  context 'course modules tab' do
    before :once do
      create_course_module
    end

    it 'has module present when provisioned' do
      get "/courses/#{@subject_course.id}#modules"

      expect(module_item(@module_title)).to be_displayed
    end

    it 'navigates to module task in edit mode when clicked' do
      get "/courses/#{@subject_course.id}#modules"

      click_module_assignment(@module_assignment_title)
      wait_for_ajaximations

      expect(assignment_page_title.text).to eq(@module_assignment_title)
      expect(assignment_edit_button).to be_displayed
    end

    it 'shows add module modal when +Module button is clicked' do
      get "/courses/#{@subject_course.id}#modules"

      click_add_module_button

      expect(add_module_modal).to be_displayed
    end

    it 'shows add module items modal when + button is clicked' do
      get "/courses/#{@subject_course.id}#modules"

      click_add_module_item_button

      expect(add_module_item_modal).to be_displayed
    end

    it 'provides drag handles for item moves' do
      get "/courses/#{@subject_course.id}#modules"

      expect(drag_handle).to be_displayed
    end
  end

  context 'course color selection' do
    it 'allows for available color to be selected', ignore_js_errors: true do
      get "/courses/#{@subject_course.id}/settings"
      visit_course_details_tab

      click_pink_color_button

      wait_for_new_page_load(submit_form('#course_form'))
      pink_color = '#DF6B91'

      expect(element_value_for_attr(selected_color_input, "value")).to eq(pink_color)
      expect(hex_value_for_color(course_color_preview)).to eq(pink_color)
    end

    it 'allows for hex color to be input', ignore_js_errors: true do
      get "/courses/#{@subject_course.id}/settings"
      visit_course_details_tab

      new_color = '#07AB99'
      input_color_hex_value(new_color)
      wait_for_new_page_load(submit_form('#course_form'))

      expect(hex_value_for_color(course_color_preview)).to eq(new_color)
    end

    it 'shows the course color selection on the course header' do
      new_color = '#07AB99'
      @subject_course.update!(course_color: new_color)

      get "/courses/#{@subject_course.id}#home"

      expect(hex_value_for_color(dashboard_header)).to eq(new_color)
    end
  end

  context 'course tab navigation' do
    let(:lti_a) { 'LTI Resource A' }
    let(:lti_b) { 'LTI Resource B' }
    let(:navigation_names) { ['Home', 'Schedule', 'Modules', 'Grades', lti_a, lti_b] }

    before :once do
      @resource_a = "context_external_tool_" + create_lti_resource(lti_a).id.to_s
      @resource_b = "context_external_tool_" + create_lti_resource(lti_b).id.to_s
    end

    it 'shows the k5 navigation tabs and LTIs on the settings page' do
      get "/courses/#{@subject_course.id}/settings#tab-navigation"

      navigation_list = navigation_items

      expect(navigation_list.count).to eq(6)

      navigation_names.count.times do |x|
        expect(navigation_list[x]).to include_text(navigation_names[x])
      end
    end

    it 'has tabs rearranged in new configuration on the subject page' do
      @subject_course.update!(
        tab_configuration: [ {id: Course::TAB_SCHEDULE}, {id: Course::TAB_HOME}, {id: Course::TAB_GRADES}, {id: Course::TAB_MODULES} ]
      )

      get "/courses/#{@subject_course.id}"

      expect(k5_tablist).to include_text("Schedule\nHome\nGrades\nModules\nResources")
    end

    it 'has tabs that are hidden from the subject page' do
      @subject_course.update!(
        tab_configuration: [ {id: Course::TAB_SCHEDULE}, {id: Course::TAB_HOME, hidden: true}, {id: Course::TAB_GRADES}, {id: Course::TAB_MODULES} ]
      )

      get "/courses/#{@subject_course.id}"

      expect(k5_tablist).to include_text("Schedule\nGrades\nModules\nResources")
    end

    it 'has ltis that are rearranged in new order on the resources page' do
      @subject_course.update!(
        tab_configuration: [{id: Course::TAB_HOME}, {id: Course::TAB_SCHEDULE}, {id: Course::TAB_GRADES}, {id: Course::TAB_MODULES}, {id: @resource_b}, {id: @resource_a}]
      )

      get "/courses/#{@subject_course.id}#resources"

      expect(k5_app_buttons[0].text).to eq lti_b
      expect(k5_app_buttons[1].text).to eq lti_a
    end

    it 'has ltis that are hidden on the resources page' do
      @subject_course.update!(
        tab_configuration: [ {id: @resource_a, hidden: true}, {id: @resource_b}]
      )

      get "/courses/#{@subject_course.id}#resources"

      expect(k5_app_buttons.count).to eq 1
      expect(k5_app_buttons[0].text).to eq lti_b
    end
  end
end
