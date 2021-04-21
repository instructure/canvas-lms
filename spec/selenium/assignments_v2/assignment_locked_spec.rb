# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

require_relative './page_objects/student_assignment_page_v2'
require_relative '../common'
require_relative '../helpers/assignments_common'


describe 'assignments' do
  include_context "in-process server selenium tests"
  include AssignmentsCommon

  context 'as a student' do

    before(:once) do
      Account.default.enable_feature!(:assignments_2_student)
      course_with_student(course: @course, active_all: true)
      @assignment = @course.assignments.create!(
        name: 'locked_assignment',
        due_at: 5.days.ago,
        lock_at: 3.days.ago
      )
    end

    before(:each) do
      user_session(@student)
      StudentAssignmentPageV2.visit(@course, @assignment)
    end

    xit 'should show locked image' do
      skip('Unskip in COMMS-2074')
      expect(StudentAssignmentPageV2.assignment_locked_image).to be_displayed
    end

    xit 'should show locked stepper' do
      skip('Unskip in COMMS-2074')
      expect(StudentAssignmentPageV2.lock_icon).to be_displayed
    end

    xit 'a locked assignment should not show details container' do
      skip('Unskip in COMMS-2074')
      expect(f("#content")).not_to contain_css StudentAssignmentPageV2.details_toggle_css
    end
  end
end
