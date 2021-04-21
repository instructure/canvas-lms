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
require_relative '../../grades/setup/gradebook_setup'

describe "student k5 dashboard schedule" do
  include_context "in-process server selenium tests"
  include K5PageObject
  include K5Common
  include GradebookSetup

  before :each do
    @account = Account.default
    @account.enable_feature!(:canvas_for_elementary)
    toggle_k5_setting(@account)
    @course_name = "K5 Course"
    course_with_teacher(
      active_course: 1,
      active_enrollment: 1,
      course_name: @course_name,
      name: 'K5Teacher1'
    )
    @now = Time.zone.now
    course_with_student_logged_in(active_all: true, new_user: true, user_name: 'KTStudent1', course: @course)

    [
      ["Today assignment",@now],
      ["Previous Assignment", 7.days.ago(@now)],
      ["Future Assignment", 7.days.from_now(@now)]
    ].each do |assignment_info|
      @course.assignments.create!(
        title: assignment_info[0],
        grading_type: 'points',
        points_possible: 100,
        due_at: assignment_info[1],
        submission_types: 'online_text_entry'
      )
    end
  end

  context 'entry' do
    it 'navigates to planner when Schedule is clicked' do

      get "/"

      select_schedule_tab
      wait_for_ajaximations

      expect(today_header).to be_displayed
    end
  end

  context 'navigation' do
    it 'starts the current week on the schedule' do

      get "/#schedule"
      wait_for_ajaximations

      expect(beginning_of_week_date).to include(beginning_weekday_calculation(@now))
      # These expects will be uncommented when a week ending issue is resolved.  LS-2042
      # expect(end_of_week_date).to include(ending_weekday_calculation(@now))
    end

    it 'navigates to previous week with previous button' do

      get "/#schedule"

      click_previous_week_button
      wait_for_ajaximations

      expect(beginning_of_week_date).to include(beginning_weekday_calculation(1.week.ago(@now)))
      # expect(end_of_week_date).to include(ending_weekday_calculation(1.week.ago(@now)))
    end

    it 'navigates to next week with the forward button' do

      get "/#schedule"

      click_next_week_button
      wait_for_ajaximations

      expect(beginning_of_week_date).to include(beginning_weekday_calculation(1.week.from_now(@now)))
      # expect(end_of_week_date).to include(ending_weekday_calculation(1.week.from_now(@now)))
    end

    it 'navigates back to current week with today button' do

      get "/#schedule"

      click_previous_week_button
      wait_for_ajaximations
      expect(beginning_of_week_date).to include(beginning_weekday_calculation(1.week.ago(@now)))

      click_today_button
      wait_for_ajaximations

      expect(beginning_of_week_date).to include(beginning_weekday_calculation(@now))
      # expect(end_of_week_date).to include(ending_weekday_calculation(@now))
    end
  end
end
