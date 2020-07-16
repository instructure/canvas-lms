#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative '../common'

shared_context "blueprint course settings context" do

  def blueprint_settings_options
    f('.blueprint_setting_options')
  end

  def content_checkbox_state
    is_checked('input[name="course[blueprint_restrictions][content]"][type=checkbox]')
  end

  def points_checkbox_state
    is_checked('input[name="course[blueprint_restrictions][points]"][type=checkbox]')
  end

  def due_dates_checkbox_state
    is_checked('input[name="course[blueprint_restrictions][due_dates]"][type=checkbox]')
  end

  def availability_dates_checkbox_state
    is_checked('input[name="course[blueprint_restrictions][availability_dates]"][type=checkbox]')
  end

end

describe "course settings/blueprint" do
  include_context "in-process server selenium tests"
  include_context "blueprint course settings context"

  before :once do
    account_admin_user
    course_factory :active_all => true
  end

  describe "as admin" do
    before :each do
      user_session @admin
    end

    it "enables blueprint course and set default restrictions", priority: "1", test_id: 3166299 do
      get "/courses/#{@course.id}/settings"
      f('.bcs_check-box').find_element(:xpath, "../div").click
      wait_for_animations
      expect(blueprint_settings_options).to be_displayed

      expect(content_checkbox_state).to eq true # checked by default
      expect(points_checkbox_state).to eq false
      expect(due_dates_checkbox_state).to eq false
      expect(availability_dates_checkbox_state).to eq false
      expect_new_page_load { submit_form('#course_form') }
      expect(MasterCourses::MasterTemplate.full_template_for(@course).default_restrictions).to eq(
        { content: true, points: false, due_dates: false, availability_dates: false }
      )
    end

    it "manipulates checkboxes" do
      template = MasterCourses::MasterTemplate.set_as_master_course(@course)
      template.default_restrictions = { points: true, due_dates: true, availability_dates: true, }
      template.save
      get "/courses/#{@course.id}/settings"

      expect_new_page_load { submit_form('#course_form') }

      expect(blueprint_settings_options).to be_displayed

      expect(content_checkbox_state).to eq false
      expect(points_checkbox_state).to eq true
      expect(due_dates_checkbox_state).to eq true
      expect(availability_dates_checkbox_state).to eq true

      expect(MasterCourses::MasterTemplate.full_template_for(@course).default_restrictions).to eq(
        { content: false, points: true, due_dates: true, availability_dates: true }
      )
    end

    it "disables blueprint course and hides restrictions" do
      template = MasterCourses::MasterTemplate.set_as_master_course(@course)
      template.default_restrictions = { content: true, due_dates: true }
      template.save!

      get "/courses/#{@course.id}/settings"

      expect(blueprint_settings_options).to be_displayed

      expect(content_checkbox_state).to eq true
      expect(points_checkbox_state).to eq false
      expect(due_dates_checkbox_state).to eq true
      expect(availability_dates_checkbox_state).to eq false

      f('.bcs_check-box').find_element(:xpath, "../div").click
      wait_for_animations
      expect_new_page_load { submit_form('#course_form') }
      expect(template.reload).to be_deleted
    end

    it "can set granular locks" do
      template = MasterCourses::MasterTemplate.set_as_master_course(@course)

      get "/courses/#{@course.id}/settings"

      expect(f('.bcs_radio_input-group')).to be_displayed
      ff('.bcs_radio_input-group')[1].click

      fj(".bcs__object-tab:contains('Assignments') .bcs_tab_indicator-icon button").click
      fj(".bcs__object-tab:contains('Assignments') .bcs_check_box-group label:contains('Content')").click
      fj(".bcs__object-tab:contains('Assignments') .bcs_check_box-group label:contains('Points')").click

      fj(".bcs__object-tab:contains('Quizzes') .bcs_tab_indicator-icon button").click
      fj(".bcs__object-tab:contains('Quizzes') .bcs_check_box-group label:contains('Due Dates')").click

      expect_new_page_load { submit_form('#course_form') }

      template.reload
      expect(template.use_default_restrictions_by_type).to be_truthy
      expect(template.default_restrictions_by_type["Assignment"]).to eq({
        content: true, points: true, due_dates: false, availability_dates: false
                                                                        })
      expect(template.default_restrictions_by_type["Quizzes::Quiz"]).to eq({
        content: false, points: false, due_dates: true, availability_dates: false
                                                                           })
    end
  end

  describe "as teacher" do
    before :each do
      user_session @teacher
    end

    it "shows No instead of a checkbox for normal courses" do
      get "/courses/#{@course.id}/settings"
      expect(f('#course_blueprint')).to include_text 'No'
    end

    it "shows Yes instead of a checkbox for blueprint courses" do
      MasterCourses::MasterTemplate.set_as_master_course(@course)
      get "/courses/#{@course.id}/settings"
      expect(f('#course_blueprint')).to include_text 'Yes'
    end

  end
end
