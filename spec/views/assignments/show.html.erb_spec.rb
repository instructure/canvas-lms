#
# Copyright (C) 2011 Instructure, Inc.
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

describe "/assignments/show" do
  it "should render" do
    course_with_teacher(active_all: true)
    view_context(@course, @user)
    g = @course.assignment_groups.create!(:name => "some group")
    a = @course.assignments.create!(:title => "some assignment")
    a.assignment_group_id = g.id
    a.save!
    assign(:assignment, a)
    assign(:assignment_groups, [g])
    assign(:current_user_rubrics, [])
    render 'assignments/show'
    expect(response).not_to be_nil # have_tag()
  end
end

