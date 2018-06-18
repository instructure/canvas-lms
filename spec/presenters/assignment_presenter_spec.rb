#
# Copyright (C) 2018 - present Instructure, Inc.
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
require_relative '../spec_helper'

describe AssignmentPresenter do
  describe '#can_view_speed_grader_link?' do
    before :once do
      # A student is used here because students do not have any special
      # permissions, so we can test that it is these specific permissions that
      # work.
      @course = Course.create!
      @student = User.create!
      @ta = User.create!
      @course.enroll_student(@student, enrollment_state: 'active')
      @course.enroll_ta(@ta, enrollment_state: 'active')
      @assignment = @course.assignments.create!(moderated_grading: false)
      @assignment_presenter = AssignmentPresenter.new(@assignment)
    end

    it 'returns true if user can manage or view all grades' do
      allow(@course).to receive(:grants_any_right?).with(@student, :manage_grades, :view_all_grades).and_return true
      expect(@assignment_presenter.can_view_speed_grader_link?(@student)).to be true
    end

    it 'returns true if concluded course but user can read as admin' do
      @course.soft_conclude!
      allow(@course).to receive(:grants_right?).with(@student, :read_as_admin).and_return true
      expect(@assignment_presenter.can_view_speed_grader_link?(@student)).to be true
    end

    it 'returns false if moderated and grader limit reached' do
      @assignment.update_attributes!(moderated_grading: true, grader_count: 2)
      allow(@course).to receive(:grants_any_right?).with(@student, :manage_grades, :view_all_grades).and_return true
      allow(@assignment).to receive(:moderated_grader_limit_reached?).and_return true
      expect(@assignment_presenter.can_view_speed_grader_link?(@student)).to be false
    end

    it 'returns true if moderated and grader limit reached but user is final grader' do
      @assignment.update_attributes!(moderated_grading: true, grader_count: 2, final_grader: @ta)
      allow(@assignment).to receive(:moderated_grader_limit_reached?).and_return true
      expect(@assignment_presenter.can_view_speed_grader_link?(@ta)).to be true
    end
  end
end
