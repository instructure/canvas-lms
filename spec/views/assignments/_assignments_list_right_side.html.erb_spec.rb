#
# Copyright (C) 2011 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../views_helper')

describe "assignments list sidebar" do
  before(:once) do
    course_with_teacher(active_all: true)
    g = @course.assignment_groups.create!(name: 'some group')
    a = @course.assignments.create!(title: 'some assignment')
    a.assignment_group_id = g.id
    a.save!
  end

  it "should render for non-students" do
    view_context(@course, @teacher)
    render 'assignments/_assignments_list_right_side'
    expect(response).to have_tag("div.events_list")
  end

  it "should not render anything for students" do
    course_with_student(active_all: true)
    view_context(@course, @student)
    render 'assignments/_assignments_list_right_side'
    expect(response).to_not have_tag('div')
  end
end
