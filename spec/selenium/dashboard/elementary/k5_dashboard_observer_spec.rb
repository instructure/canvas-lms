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
require_relative '../pages/k5_dashboard_common_page'
require_relative '../../../helpers/k5_common'

describe "observer k5 dashboard" do
  include_context "in-process server selenium tests"
  include K5DashboardPageObject
  include K5DashboardCommonPageObject
  include K5Common

  before :once do
    Account.site_admin.enable_feature!(:k5_parent_support)
    student_setup
    observer_setup
  end

  before :each do
    user_session @observer
    driver.manage.delete_cookie('k5_observed_user_id')
  end

  context 'single observed student' do
    it 'provides the label for one observed student' do
      get "/"

      expect(observed_student_label).to be_displayed
    end
  end

  context 'multiple observed students' do
    before :once do
      2.times do |x|
        course_with_student(
          active_all: true,
          name: "My#{x + 1} Student",
          course: @homeroom_course
        )
        add_linked_observer(@student, @observer, root_account: @account)
      end
    end

    it 'provides a dropdown for multiple observed students' do
      get "/"

      expect(observed_student_dropdown).to be_displayed

      expect(element_value_for_attr(observed_student_dropdown,'value')).to eq('K5Student')
    end

    it 'selects a student from the dropdown list' do
      get "/"

      click_observed_student_option('My1 Student')

      expect(element_value_for_attr(observed_student_dropdown,'value')).to eq('My1 Student')
    end

    it 'selects allows for searching for a student in dropdown list' do
      get "/"

      observed_student_dropdown.send_keys([:control, 'a'], :backspace, 'My2')
      click_observed_student_option('My2 Student')

      expect(element_value_for_attr(observed_student_dropdown,'value')).to eq('My2 Student')
    end

    it 'shows the observers name first if observer is also a student' do
      course_with_student(
        active_all: true,
        user: @observer,
        course: @homeroom_course
      )

      get "/"

      expect(element_value_for_attr(observed_student_dropdown,'value')).to eq('Mom')
    end

  end
end
