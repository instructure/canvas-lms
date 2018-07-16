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
require_relative '../../spec_helper'
require_relative '../views_helper'

describe '_grade_assignment' do
  it 'renders a speedgrader link if user can view all grades but not manage grades' do
    course_with_ta
    @course.account.role_overrides.create!(permission: 'manage_grades', role: ta_role, enabled: false)
    view_context(@course, @ta)
    assignment = @course.assignments.create!(title: 'an assignment')
    assign(:assignment, assignment)
    assign(:assignment_presenter, AssignmentPresenter.new(assignment))
    render partial: 'assignments/grade_assignment'
    expect(response).to have_tag("a[href=\"/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{assignment.id}\"]")
  end

  it 'renders a speedgrader link if user can manage grades but not view all grades' do
    course_with_ta
    @course.account.role_overrides.create!(permission: 'view_all_grades', role: ta_role, enabled: false)
    view_context(@course, @ta)
    assignment = @course.assignments.create!(title: 'an assignment')
    assign(:assignment, assignment)
    assign(:assignment_presenter, AssignmentPresenter.new(assignment))
    render partial: 'assignments/grade_assignment'
    expect(response).to have_tag("a[href=\"/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{assignment.id}\"]")
  end

  it 'does not render a speedgrader link if user can neither view all grades nor manage grades' do
    course_with_ta
    @course.account.role_overrides.create!(permission: 'view_all_grades', role: ta_role, enabled: false)
    @course.account.role_overrides.create!(permission: 'manage_grades', role: ta_role, enabled: false)
    view_context(@course, @ta)
    assignment = @course.assignments.create!(title: 'an assignment')
    assign(:assignment, assignment)
    assign(:assignment_presenter, AssignmentPresenter.new(assignment))
    render partial: 'assignments/grade_assignment'
    expect(response).not_to have_tag("a[href=\"/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{assignment.id}\"]")
  end
end
