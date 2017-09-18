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

require_relative '../pages/gradezilla_page'
require_relative '../pages/gradezilla_cells_page'
require_relative '../pages/gradezilla_late_policies_page'
require_relative '../pages/gradezilla_main_settings'

describe 'Late Policies:' do
  include_context "in-process server selenium tests"


  context 'when applied' do
    before(:once) do
      now = Time.zone.now

      # create course with teacher and student
      course_factory(active_all: true)
      student_in_course

      # create late/missing policies on backend
      @course.create_late_policy(
        missing_submission_deduction_enabled: true,
        missing_submission_deduction: 50.0,
        late_submission_deduction_enabled: true,
        late_submission_deduction: 10.0,
        late_submission_interval: 'day',
        late_submission_minimum_percent_enabled: true,
        late_submission_minimum_percent: 50.0,
      )

      # create 3 assignments due in the past
      @a1 = @course.assignments.create!(
        title: 'assignment one',
        grading_type: 'points',
        points_possible: 100,
        due_at: 1.day.ago(now),
        submission_types: 'online_text_entry'
      )

      @a2 = @course.assignments.create!(
        title: 'assignment two',
        grading_type: 'points',
        points_possible: 100,
        due_at: 1.day.ago(now),
        submission_types: 'online_text_entry'
      )

      @a3 = @course.assignments.create!(
        title: 'assignment three',
        grading_type: 'points',
        points_possible: 10,
        due_at: 1.week.ago(now),
        submission_types: 'online_text_entry'
      )

      # as a student submit 2 assignments late
      Timecop.freeze(2.hours.ago(now)) do
        @a1.submit_homework(@student, body: 'submitting my homework')
        @a3.submit_homework(@student, body: 'submitting my homework')
      end

      # as a teacher grade the late assignments
      @a1.grade_student(@student, grade: 90, grader: @teacher)
      @a3.grade_student(@student, grade: 9, grader: @teacher)
    end

    before(:each) do
      ENV["GRADEBOOK_DEVELOPMENT"] = "true"
      user_session(@teacher)
      Gradezilla.visit(@course)
    end

    after(:each) { ENV.delete("GRADEBOOK_DEVELOPMENT") }

    it 'late policy adjusts grades correctly', test_id: 3196973, priority: '1' do
      expect(Gradezilla::Cells.get_grade(@student, @a1)).to eq "80"
    end

    it 'missing policy adjusts grades correctly', test_id: 3196972, priority: '1' do
      expect(Gradezilla::Cells.get_grade(@student, @a2)).to eq "50"
    end

    it 'late policy with floor adjust the grades correctly', test_id: 3196974, priority: '1' do
      expect(Gradezilla::Cells.get_grade(@student, @a3)).to eq "5"
    end
  end

  context 'when created' do
    before(:once) do
      course_factory(active_all: true)
      student_in_course
    end

    before(:each) do
      ENV["GRADEBOOK_DEVELOPMENT"] = "true"
      user_session(@teacher)
      Gradezilla.visit(@course)
      Gradezilla.settings_cog_select
    end

    after(:each) { ENV.delete("GRADEBOOK_DEVELOPMENT") }

    it 'saves late policy', test_id: 3196970, priority: '1' do
      percentage = 10
      increment = 'Day'
      MainSettings::LatePolicies.create_late_policy(percentage, increment)
      MainSettings::Controls.click_update_button

      expect(@course.late_policy.late_submission_deduction_enabled).to be true
      expect(@course.late_policy.late_submission_deduction.to_i).to be percentage
      expect(@course.late_policy.late_submission_interval).to eq increment.downcase
    end

    it 'saves missing policy', test_id: 3196968, priority: '1' do
      percentage = 50
      MainSettings::LatePolicies.create_missing_policy(percentage)
      MainSettings::Controls.click_update_button

      expect(@course.late_policy.missing_submission_deduction_enabled).to be true
      expect(@course.late_policy.missing_submission_deduction.to_i).to be percentage

    end

    it 'saves late policy with floor', test_id: 3196971, priority: '1' do
      percentage = 10
      increment = 'Day'
      lowest_percentage = 50
      MainSettings::LatePolicies.create_late_policy(percentage, increment, lowest_percentage)
      MainSettings::Controls.click_update_button

      expect(@course.late_policy.late_submission_minimum_percent_enabled).to be true
      expect(@course.late_policy.late_submission_minimum_percent.to_i).to be lowest_percentage
    end
  end
end
