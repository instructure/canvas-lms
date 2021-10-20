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

require_relative '../common'
require_relative 'pages/paceplans_common_page'
require_relative 'pages/paceplans_page'
require_relative '../courses/pages/courses_home_page'

describe 'pace plan page' do
  include_context 'in-process server selenium tests'
  include PacePlansCommonPageObject
  include PacePlansPageObject
  include CoursesHomePage

  before :once do
    teacher_setup
    enable_pace_plans_in_course
  end

  before :each do
    user_session @teacher
  end

  context 'pace plans in course navigation' do
    it 'navigates to the pace plans page when Pace Plans is clicked' do
      visit_course(@course)

      click_pace_plans

      expect(driver.current_url).to include("/courses/#{@course.id}/pace_plans")
    end

    it 'shows the module in the pace plan' do
      module_title = 'First Module'
      create_course_module(module_title, 'active', 'published')

      visit_pace_plans_page

      expect(module_title_text(pace_plan_table_module_elements[0])).to include(module_title)
    end
  end
end
