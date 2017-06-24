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

describe "course settings/blueprint" do
  include_context "in-process server selenium tests"

  before :once do
    Account.default.enable_feature! :master_courses
    account_admin_user
    course_factory :active_all => true
  end

  describe "as admin" do
    before :each do
      user_session @admin
    end

    it "enables blueprint course and set default restrictions" do
      get "/courses/#{@course.id}/settings"
      f('.bcs_check-box').find_element(:xpath, "../div").click
      wait_for_animations
      expect(f('.blueprint_setting_options')).to be_displayed
      expect(is_checked('input[name="course[blueprint_restrictions][content]"]')).not_to be
      expect(is_checked('input[name="course[blueprint_restrictions][points]"]')).not_to be
      expect(is_checked('input[name="course[blueprint_restrictions][due_dates]"]')).not_to be
      expect(is_checked('input[name="course[blueprint_restrictions][availability_dates]"]')).not_to be
    end

    it "manipulates checkboxes" do
      template = MasterCourses::MasterTemplate.set_as_master_course(@course)
      template.default_restrictions = { :points => true, :due_dates => true, :availability_dates => true, }
      template.save
      get "/courses/#{@course.id}/settings"

      expect_new_page_load { submit_form('#course_form') }

      expect(f('.blueprint_setting_options')).to be_displayed
      expect(is_checked('input[name="course[blueprint_restrictions][points]"]')).not_to be
      expect(is_checked('input[name="course[blueprint_restrictions][due_dates]"]')).not_to be
      expect(is_checked('input[name="course[blueprint_restrictions][availability_dates]"]')).not_to be

      expect(MasterCourses::MasterTemplate.full_template_for(@course).default_restrictions).to eq(
        { :content => false, :points => true, :due_dates => true, :availability_dates => true }
      )
    end

    it "disables blueprint course and hides restrictions" do
      template = MasterCourses::MasterTemplate.set_as_master_course(@course)
      template.default_restrictions = { :content => true, :due_dates => true }
      template.save!

      get "/courses/#{@course.id}/settings"

      expect(f('.blueprint_setting_options')).to be_displayed
      expect(is_checked('input[name="course[blueprint_restrictions][points]"]')).not_to be
      expect(is_checked('input[name="course[blueprint_restrictions][due_dates]"]')).not_to be
      expect(is_checked('input[name="course[blueprint_restrictions][availability_dates]"]')).not_to be

      f('.bcs_check-box').find_element(:xpath, "../div").click
      wait_for_animations
      expect_new_page_load { submit_form('#course_form') }

    end
  end

  describe "as teacher" do
    before :each do
      user_session @teacher
    end

    it "shows No instead of a checkbox for normal courses" do
      get "/courses/#{@course.id}/settings"
      expect(f('#course_blueprint').text).to include 'No'
    end

    it "shows Yes instead of a checkbox for blueprint courses" do
      MasterCourses::MasterTemplate.set_as_master_course(@course)
      get "/courses/#{@course.id}/settings"
      expect(f('#course_blueprint').text).to include 'Yes'
    end

  end
end
