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

describe "admin k5 dashboard" do
  include_context "in-process server selenium tests"
  include K5PageObject
  include K5Common

  before :once do
    admin_setup
  end

  before :each do
    user_session @admin
  end

  context 'homeroom dashboard standard' do
    it 'provides the homeroom dashboard tabs on dashboard' do
      get "/"

      expect(retrieve_welcome_text).to match(/Welcome,/)
      expect(homeroom_tab).to be_displayed
      expect(schedule_tab).to be_displayed
      expect(grades_tab).to be_displayed
      expect(resources_tab).to be_displayed
    end
  end

  context 'new course creation' do
    it 'provides a new course button for admin' do
      get "/"

      expect(new_course_button).to be_displayed
    end

    it 'provides a new course modal when new course button clicked' do
      get "/"

      click_new_course_button

      expect(new_course_modal).to be_displayed
    end

    it 'closes the course modal when x is clicked' do
      get "/"

      click_new_course_button

      expect(new_course_modal_close_button).to be_displayed

      click_new_course_close_button

      expect(new_course_modal_exists?).to be_falsey
    end

    it 'closes the course modal when cancel is clicked' do
      get "/"

      click_new_course_button

      expect(new_course_modal_close_button).to be_displayed

      course_name = "Awesome Course"
      fill_out_course_modal(course_name)

      click_new_course_cancel

      expect(new_course_modal_exists?).to be_falsey
      latest_course = Course.last
      expect(latest_course.name).not_to eq(course_name)
    end

    it 'creates course with account name and course name', ignore_js_errors: true, custom_timeout: 25 do
      get "/"

      click_new_course_button

      course_name = "Awesome Course"

      fill_out_course_modal(course_name)
      click_new_course_create
      wait_for_ajaximations

      expect(new_course_modal_exists?).to be_falsey

      latest_course = Course.last
      expect(latest_course.name).to eq(course_name)
      expect(driver.current_url).to include("/courses/#{latest_course.id}/settings")
    end
  end

  context 'admin schedule' do
    it 'shows a sample preview for admin (teacher) view of the schedule tab' do
      get "/#schedule"

      expect(teacher_preview).to be_displayed
    end

    it 'shows a sample preview for admin (teacher) view of the course schedule tab' do
      get "/courses/#{@subject_course.id}#schedule"

      expect(teacher_preview).to be_displayed
    end
  end
end
