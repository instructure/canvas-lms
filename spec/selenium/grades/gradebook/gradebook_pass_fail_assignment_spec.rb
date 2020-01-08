#
# Copyright (C) 2015 - present Instructure, Inc.
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

require_relative '../../helpers/gradebook_common'

describe "gradebook" do
  include_context "in-process server selenium tests"
  include GradebookCommon

  context 'pass/fail assignment grading' do
    before :once do
      init_course_with_students 1
      @assignment = @course.assignments.create!(grading_type: 'pass_fail', points_possible: 0)
      @assignment.grade_student(@students[0], grade: 'pass', grader: @teacher)
    end

    before :each do
      user_session(@teacher)
    end

    it 'should allow pass grade on assignments worth 0 points', priority: "1", test_id: 330310 do
      get "/courses/#{@course.id}/gradebook"
      expect(f('button.gradebook-checkbox.gradebook-checkbox-pass')).to include_text('pass')
    end

    it 'should display pass/fail correctly when total points possible is changed', priority: "1", test_id: 419288 do
      @assignment.update(points_possible: 1)
      get "/courses/#{@course.id}/gradebook"
      expect(f('button.gradebook-checkbox.gradebook-checkbox-pass')).to include_text('pass')
    end
  end
end
