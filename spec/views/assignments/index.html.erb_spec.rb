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

describe "/assignments/index" do
  it "should render" do
    course_with_teacher
    view_context(@course, @user)
    a = @course.assignments.create!(:title => "some assignment")
    g = @course.assignment_groups.create!(:name => "some group")
    a.assignment_group_id = g.id
    a.save!
    assigns[:groups] = [g]
    assigns[:assignment_groups] = assigns[:groups]
    render 'assignments/index'
    expect(response).to have_tag('div#groups')
  end
end

