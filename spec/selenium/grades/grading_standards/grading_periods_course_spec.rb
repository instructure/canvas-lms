#
# Copyright (C) 2015-2016 Instructure, Inc.
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
#

require_relative '../../common'

describe 'Course Grading Periods' do
  include_examples 'in-process server selenium tests'

  let(:group_helper) { Factories::GradingPeriodGroupHelper.new }
  let(:period_helper) { Factories::GradingPeriodHelper.new }

  context 'with Multiple Grading Periods feature on,' do
    before(:each) do
      course_with_teacher_logged_in
      @course.root_account.enable_feature!(:multiple_grading_periods)
    end

    it 'shows grading periods created at the course-level', priority: "1", test_id: 239998 do
      @course_grading_period = period_helper.create_with_group_for_course(@course)
      get "/courses/#{@course.id}/grading_standards"
      period_title = f("#period_title_#{@course_grading_period.id}")
      expect(period_title).to have_value(@course_grading_period.title)
    end

    it 'allows grading periods to be deleted', priority: "1", test_id: 202320 do
      grading_period_selector = '.grading-period'
      group = group_helper.legacy_create_for_course(@course)
      period_helper.create_with_weeks_for_group(group, 5, 3)
      period_helper.create_with_weeks_for_group(group, 3, 1)
      get "/courses/#{@course.id}/grading_standards"
      expect(ff(grading_period_selector).length).to be 2
      f('.icon-delete-grading-period').click
      driver.switch_to.alert.accept
      wait_for_ajaximations
      expect(ff(grading_period_selector).length).to be 1
    end

    it 'allows updating grading periods', priority: "1", test_id: 202317 do
      period_helper.create_with_group_for_course(@course)
      get "/courses/#{@course.id}/grading_standards"
      expect(f("#update-button")).to be_present
    end
  end
end

# there is a lot of repeated code in the inheritance tests, since we are testing 3 roles on 3 pages
# the way this works will change soon (MGP version 3), so it makes more sense to wait for these
# changes before refactoring these tests
describe 'Course Grading Periods Inheritance' do
  include_examples 'in-process server selenium tests'

  let(:title) {'hi'}
  let(:start_date) { format_date_for_view(3.months.from_now) }
  let(:end_date) { format_date_for_view(4.months.from_now - 1.day) }

  before(:each) do
    course_with_admin_logged_in
    @account = @course.root_account
    @account.enable_feature!(:multiple_grading_periods)

    course_with_teacher(course: @course, name: 'teacher', active_enrollment: true)
    @account_course = @course
    @account_teacher = @teacher
  end

  context 'with Multiple Grading Periods feature on,' do
    it 'reads course grading periods', priority: "1", test_id: 202318 do
      user_session @account_teacher
      course_grading_period = Factories::GradingPeriodHelper.new.create_with_group_for_course(@course)
      get "/courses/#{@account_course.id}/grading_standards"
      expect(ff('.grading-period').length).to be(1)
      expect(f("#period_title_#{course_grading_period.id}")).to have_value(course_grading_period.title)
    end
  end
end
