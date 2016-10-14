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

require_relative './common'
require_relative './helpers/gradebook2_common'

describe "interaction with multiple grading periods" do
  include_context "in-process server selenium tests"
  include Gradebook2Common

  let(:group_helper) { Factories::GradingPeriodGroupHelper.new }
  let(:get_gradebook) { get "/courses/#{@course.id}/gradebook" }

  context "gradebook" do
    before :each do
      gradebook_data_setup(grading_periods: [:future, :current])
    end

    it "should display the correct grading period based on the GET param" do
      future_period = @course.grading_periods.detect{|gp| gp.start_date.future?}
      get "/courses/#{@course.id}/gradebook?grading_period_id=#{future_period.id}"
      expect(f('.grading-period-select-button')).to include_text(future_period.title)
    end

    it "should display All Grading Periods when grading period id is set to 0" do
      get "/courses/#{@course.id}/gradebook?grading_period_id=0"
      expect(f('.grading-period-select-button')).to include_text("All Grading Periods")
    end

    it "should display the current grading period without a GET param" do
      current_period = @course.grading_periods.detect{|gp| gp.start_date.past? && gp.end_date.future?}
      get "/courses/#{@course.id}/gradebook"
      expect(f('.grading-period-select-button')).to include_text(current_period.title)
    end

    context "using multiple grading period dropdown" do
      it 'should display current grading period on load', test_id: 2528634, priority: "2" do
        get_gradebook
        element = ff('.slick-header-column a').select { |a| a.text == 'assignment three' }
        expect(element.first).to be_displayed
      end

      it 'filters assignments when different grading periods selected', test_id: 2528635, priority: "2" do
        get_gradebook
        f('.grading-period-select-button').click
        fj('.ui-menu-item label:contains("Course Period 1: future period")').click
        wait_for_ajaximations
        element = ff('.slick-header-column a').select { |a| a.text == 'second assignment' }
        expect(element.first).to be_displayed
      end

      it 'displays all assignments when all grading periods selected', test_id: 2528636, priority: "2" do
        get_gradebook
        f('.grading-period-select-button').click
        fj('.ui-menu-item label:contains("All Grading Periods")').click
        wait_for_ajaximations

        element = ff('.slick-header-column a').select { |a| a.text == 'assignment three' }
        expect(element.first).to be_displayed
        element = ff('.slick-header-column a').select { |a| a.text == 'second assignment' }
        expect(element.first).to be_displayed
      end
    end
  end

  context 'grading schemes' do
    let(:account) { Account.default }
    let(:admin) { account_admin_user(:account => account) }
    let!(:enable_mgp_flag) { account.enable_feature!(:multiple_grading_periods) }
    let(:test_course) { account.courses.create!(name: 'New Course') }

    it 'should still be functional with mgp flag turned on and disable adding during edit mode', priority: "1", test_id: 545585 do
      user_session(admin)
      get "/courses/#{test_course.id}/grading_standards"
      f('#react_grading_tabs a[href="#grading-standards-tab"]').click
      f('button.add_standard_button').click
      expect(f('input.scheme_name')).not_to be_nil
      expect(f('button.add_standard_button')).to have_class('disabled')
    end

    context 'assignment index page' do
      let(:account) { Account.default }
      let(:teacher) { user(active_all: true) }
      let!(:enroll_teacher) { test_course.enroll_user(teacher, 'TeacherEnrollment', enrollment_state: 'active') }
      let!(:enable_mgp_flag) { account.enable_feature!(:multiple_grading_periods) }
      let!(:enable_course_mgp_flag) { test_course.enable_feature!(:multiple_grading_periods) }
      let!(:grading_period_group) { group_helper.legacy_create_for_course(test_course) }
      let!(:course_grading_period_current) do
        grading_period_group.grading_periods.create!(
          title: 'Course Grading Period 1',
          start_date: Time.zone.now,
          end_date: 4.weeks.from_now
        )
      end
      let!(:course_grading_period_past) do
        grading_period_group.grading_periods.create!(
          title: 'Course Grading Period 2',
          start_date: 4.weeks.ago,
          end_date: 1.day.ago
        )
      end
      let!(:assignment) { test_course.assignments.create!(title: 'Assignment 1', due_at: 1.day.ago, points: 10) }

      it 'should list an assignment from a previous grading period', priority: "2", test_course: 381145 do
        user_session(teacher)
        get "/courses/#{test_course.id}/assignments"
        expect(fj("#assignment_#{assignment.id} a.ig-title")).to include_text('Assignment 1')
      end

      it 'should list an assignment from a current grading period when due date is updated', priority: "2", test_course: 576764 do
        assignment.update_attributes(due_at: 3.days.from_now)
        user_session(teacher)
        get "/courses/#{test_course.id}/assignments"
        expect(fj("#assignment_#{assignment.id} a.ig-title")).to include_text('Assignment 1')
      end
    end
  end

  context 'student view' do
    let(:account) { Account.default }
    let(:test_course) { account.courses.create!(name: 'New Course') }
    let(:student) { user(active_all: true) }
    let!(:enroll_student) { test_course.enroll_user(student, 'StudentEnrollment', enrollment_state: 'active') }
    let!(:enable_mgp_flag) { account.enable_feature!(:multiple_grading_periods) }
    let!(:enable_course_mgp_flag) { test_course.enable_feature!(:multiple_grading_periods) }
    let!(:grading_period_group) { group_helper.legacy_create_for_course(test_course) }
    let!(:course_grading_period_1) do
      grading_period_group.grading_periods.create!(
        title: 'Course Grading Period 1',
        start_date: Time.zone.now,
        end_date: 3.weeks.from_now
      )
    end
    let!(:course_grading_period_2) do
      grading_period_group.grading_periods.create!(
        title: 'Course Grading Period 2',
        start_date: 4.weeks.from_now,
        end_date: 7.weeks.from_now
      )
    end
    let!(:assignment1) { test_course.assignments.create!(title: 'Assignment 1', due_at: 3.days.from_now, points: 10) }
    let!(:assignment2) { test_course.assignments.create!(title: 'Assignment 2', due_at: 6.weeks.from_now, points: 10) }
    let!(:grade_assignment1) { assignment1.grade_student(student, { grade: 8 }) }

    before(:each) do
      test_course.offer!
      user_session(student)
      get "/courses/#{test_course.id}/grades"
    end

    it 'should display the current grading period and assignments in grades page', priority: "1", test_id: 202326 do
      expect(f(".grading_periods_selector option[selected='selected']")).to include_text('Course Grading Period 1')
      expect(f("#submission_#{assignment1.id} th a")).to include_text('Assignment 1')
    end

    it 'should update assignments when a different period is selected in grades page', priority: "1", test_id: 562596 do
      fj(".grading_periods_selector option:nth-child(3)").click
      expect(fj("#submission_#{assignment2.id} th a")).to include_text('Assignment 2')
    end

    it 'should update assignments when a different period is selected in grades page', priority: "1", test_id: 571756 do
      fj(".grading_periods_selector option:nth-child(1)").click
      expect(fj("#submission_#{assignment1.id} th a")).to include_text('Assignment 1')
      expect(fj("#submission_#{assignment2.id} th a")).to include_text('Assignment 2')
    end
  end
end
